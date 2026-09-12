#!/usr/bin/env -S deno run --allow-read
//
// lint-yml.deno.ts — field-level linter for src/**/*.yml
//
// Encodes the lessons learned during the 2026-09 schema tightening.
// Each rule has a short note explaining the bug it guards against.
//
// Output: TSV (file\tline\trule\tmessage) so it pipelines with `x ajv`.
// Exit 1 on any issue, 0 on clean.
//
// Usage:
//   deno run --allow-read .x-cmd/lint-yml.deno.ts                # lint src/
//   deno run --allow-read .x-cmd/lint-yml.deno.ts path/a.yml …   # lint given files

import { walk } from "jsr:@std/fs/walk";
import { relative } from "jsr:@std/path";

// ─── Patterns for x: shortcut values ─────────────────────────────────────
// Mirrors .vscode/install.schema.json. Per-key patterns:
//
//   source     https URL — required by design
//   eget       owner/repo — NOT a full URL (was a widespread bug; install-x-shortcut
//              captured the rule: cmd URL instead of the bare `owner/repo`)
//   others     General package-name pattern: strict enough to reject garbage
//              (`--cask`, `&&`, `.`) but permissive enough for any legitimate
//              package name across PMs (scoped npm, brew taps, Gentoo
//              categories, nix attrs, go URLs).
//
// First char: alphanumeric OR `@` (npm scoped). Then any of: alphanumeric,
// `_`, `.`, `@`, `/`, `+`, `:`, `-`, `#`, `[`, `]`, `~`, `?`. Length 1-256.
const SOURCE_PATTERN  = /^https?:\/\/\S+$/;
const EGET_PATTERN    = /^[A-Za-z0-9][A-Za-z0-9_.+-]{0,127}\/[A-Za-z0-9][A-Za-z0-9_.+-]{0,127}$/;
const GENERAL_PATTERN = /^[A-Za-z0-9@][A-Za-z0-9_.@\/+:\-#\[\]~?]{0,255}$/;

// Keys that may appear under x: but are *not* PM shortcuts — handled separately.
const STRUCTURAL_X_KEYS = new Set(["pkg", "source", "eget", "x", "x-cmd"]);

// Strip surrounding YAML quoting from a raw value. The schema sees parsed
// strings; we see raw text, so we have to undo double-quoting ourselves.
function unquote(v: string): string {
    const s = v.trim();
    if ((s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"))) {
        return s.slice(1, -1);
    }
    return s;
}

// ─── Issue collector ──────────────────────────────────────────────────────
interface Issue { file: string; line: number; rule: string; message: string }
const ISSUES: Issue[] = [];
function add(file: string, line: number, rule: string, message: string) {
    ISSUES.push({ file, line, rule, message });
}

// ─── Per-file lint ────────────────────────────────────────────────────────
async function lintFile(path: string): Promise<void> {
    const text = await Deno.readTextFile(path);
    const lines = text.split("\n");

    // Track which top-level block we're in: "x", "rule", or null.
    // `subKeys` resets per rule: entry (key at 2-space indent) so we can
    // catch duplicate `reference:` within a single entry.
    let block: "x" | "rule" | null = null;
    let subKeys = new Set<string>();

    for (let i = 0; i < lines.length; i++) {
        const raw = lines[i];
        const ln = i + 1;
        const stripped = raw.replace(/\s+$/, "");

        // Top-level key — switches the block context.
        const top = stripped.match(/^([a-z][\w-]*):\s*$/);
        if (top && !raw.startsWith(" ") && !raw.startsWith("\t")) {
            if (top[1] === "x") {
                block = "x"; subKeys = new Set();
            } else if (top[1] === "rule") {
                block = "rule"; subKeys = new Set();
            } else if (/^[a-z]/.test(top[1])) {
                block = null; subKeys = new Set();
            }
            continue;
        }

        // ─── Inside x: block ──────────────────────────────────────────────
        if (block === "x" && /^  \S/.test(raw)) {
            const m = stripped.match(/^  (\S+):\s*(.*)$/);
            if (!m) continue;
            const [, key, rawValue] = m;
            const value = unquote(rawValue);

            // R01: pkg must be { exist: bool } — not a FreeBSD package name
            // Bug: install-x-shortcut extracted `pkg install gohugo` as
            // `x: pkg: gohugo` instead of leaving pkg: { exist: true }.
            if (key === "pkg" && value && !value.startsWith("{")) {
                add(path, ln, "pkg-as-string",
                    `x: pkg must be { exist: bool }, got string: ${value}`);
            }

            // R02: trailing single quote on a value
            // Bug: the regex `\S+` in install-x-shortcut swallowed the
            // closing quote of rule: cmd: 'apt install foo' → 'foo' as value.
            if (value.endsWith("'") && !value.endsWith("\\'")) {
                add(path, ln, "trailing-quote",
                    `value has trailing single quote: ${value}`);
            }

            // R03: concatenated next-key on the same line
            // Bug: when install-x-shortcut appended a new shortcut to an x:
            // block whose last line ended mid-scalar, the next line's key
            // got glued: `brew: pyenvrule:` should be `brew: pyenv\nrule:`.
            const CONCAT_KEYS = ["rule", "binlist", "license", "desc",
                                 "homepage", "lang", "footprint", "x"];
            for (const k of CONCAT_KEYS) {
                const concatRe = new RegExp(`^${k}:$`);
                if (concatRe.test(value) || (value.includes(`${k}:`) && /\w$/.test(value.split(`${k}:`)[0]))) {
                    add(path, ln, "concat-line",
                        `value concatenated with "${k}:": ${value}`);
                    break;
                }
            }

            // R04: flag-looking value (--foo, -foo)
            // Bug: `brew install --cask osquery` captured `--cask` instead of `osquery`.
            if (/^-{1,2}[\w-]+$/.test(value) || value.includes("=") && /^-/.test(value)) {
                add(path, ln, "flag-as-value",
                    `looks like a CLI flag, not a package: ${value}`);
            }

            // R05: local file path
            // Bug: `apt install ./hurl_$VERSION_amd64.deb` captured the path.
            if (/^\.\.?[\\/]/.test(value) ||
                /\.(deb|rpm|pkg\.tar|nupkg)$/i.test(value) ||
                /^\$\{?\w+\}?/.test(value)) {
                add(path, ln, "local-path",
                    `local file or var, not a package: ${value}`);
            }

            // R06: shell operator captured as value
            // Bug: `npm install && npm run dev` captured `&&`.
            if (/^[&|;><]/.test(value)) {
                add(path, ln, "shell-op",
                    `shell operator captured as value: ${value}`);
            }

            // R07: escape sequence leaked into value
            // Bug: `dnf: ibus\*` from rule cmd: `dnf install ibus\*`.
            if (value.includes("\\")) {
                add(path, ln, "escape-leak",
                    `escape sequence leaked into value: ${value}`);
            }

            // R08: PM shortcut value must match the right per-key pattern
            if (value && key !== "pkg") {
                if (key === "source" && !SOURCE_PATTERN.test(value)) {
                    add(path, ln, "source-not-url",
                        `x: source must be a URL: ${value}`);
                } else if (key === "eget" && !EGET_PATTERN.test(value)) {
                    add(path, ln, "eget-not-owner-repo",
                        `x: eget must be owner/repo (no protocol): ${value}`);
                } else if (!STRUCTURAL_X_KEYS.has(key) && !GENERAL_PATTERN.test(value)) {
                    add(path, ln, "pattern-violation",
                        `value fails general pattern ^[A-Za-z0-9@][A-Za-z0-9_.@/+:\\-#\\[\\]~?]{0,255}$: ${value}`);
                }
            }

            // R09: rule-like key nested under x: (should be top-level rule:)
            // Bug: file had `x: ... /eget: ... darwin/brew: ...` all indented
            // at 2 spaces under x:. These should be under rule: at 0 indent.
            if (/^[/(][\w./-]+[/:]$/.test(key) ||
                /^[\w-]+\/(?:brew|apt|dnf|yum|pacman|port|emerge|xbps|zypper|apk|choco|scoop|winget|curl|wget|pkg|go|cargo|nix|snap|flatpak):?$/.test(key)) {
                add(path, ln, "rule-under-x",
                    `rule-style key nested under x: ${key} — move to top-level rule:`);
            }

            subKeys.add(key);
        }

        // ─── Inside rule: block ───────────────────────────────────────────
        if (block === "rule") {
            // New rule: sub-entry at 2-space indent — reset subKeys.
            const entry = stripped.match(/^  (\S+):\s*$/);
            if (entry) {
                subKeys = new Set();
                continue;
            }
            // Sub-entry key (cmd/reference/dsnap) at 4-space indent.
            // Track which keys we've seen, so orphan-reference below can
            // tell whether `reference:` has a sibling `cmd:` above it.
            // NOTE: duplicate keys (e.g. two `reference:` lines under the
            // same entry) are caught by the YAML parser and reported by
            // `x ajv` as syntax-error — we don't duplicate that here.
            const sub = stripped.match(/^    (\w+):/);
            if (sub) {
                subKeys.add(sub[1]);
                continue;
            }
            // Orphan reference: at wrong indent (no parent entry above).
            if (/^    reference:/.test(raw) && subKeys.size === 0) {
                add(path, ln, "orphan-reference",
                    `"reference:" with no parent cmd: — likely indentation bug`);
            }
        }
    }
}

// ─── CLI ───────────────────────────────────────────────────────────────────
if (import.meta.main) {
    const args = Deno.args;
    let files: string[] = [];
    if (args.length > 0) {
        files = args;
    } else {
        for await (const e of walk("src", { exts: [".yml"], includeDirs: false })) {
            files.push(e.path);
        }
    }

    for (const f of files) {
        await lintFile(f);
    }

    const here = Deno.cwd();
    for (const i of ISSUES) {
        const rel = relative(here, i.file);
        console.log(`${rel}\t${i.line}\t${i.rule}\t${i.message}`);
    }

    if (ISSUES.length > 0) {
        console.error(`\n${ISSUES.length} issue(s) across ${new Set(ISSUES.map(i => i.file)).size} file(s)`);
        Deno.exit(1);
    }
}