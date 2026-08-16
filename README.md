# x-cmd install

Three things to keep straight:

1. **[x-cmd](https://x-cmd.com)** — a POSIX shell superpowers toolkit. The thing you install and run.
2. **`x install`** / **`x eget`** — two commands inside x-cmd that resolve "how do I get tool X onto my machine?". `x install` picks the best available install rule; `x eget` fetches a prebuilt binary from a GitHub release. (See [`x-cmd.com/mod/install`](https://x-cmd.com/mod/install) and [`x-cmd.com/mod/eget`](https://x-cmd.com/mod/eget).)
3. **This repository (`x-cmd-install/install`)** — the **data** those commands consume. Not the code, not the modules — just the curated YAML index: for each of 2,350+ tools, the install rules per OS / per package manager.

In short: x-cmd has the brain; this repo has the lookup table.

> 📦 **2,350+ packages** across 70+ categories under [`src/`](src).
> 🚀 Daily-rebuilt artifacts (TSV + tar.xz) ship as **immutable `vYYYYMMDD` GitHub Releases** at 12:00 UTC (= 20:00 Asia/Shanghai). Consumers fetch from the latest release (marked "Latest"), **not** from `main`.

---

## Our stance

We welcome interesting new tools, and we don't judge by stars or popularity. Closed-source, commercial, and AI-generated are all fine — what we don't accept are tools with no human thinking behind them, no safety consideration, and no long-term maintenance plan.

That said, this isn't a marketing page. The following are auto-declined, and existing entries that turn out to fall into any of these will be tagged yellow or removed:

- Tools that engage in **malicious behavior**
- Tools that **collect user privacy** without clear, prominent disclosure
- Tools that **hide what they do** — undocumented network calls, hidden background processes, obfuscated payloads

`x install` runs on the user's machine, so the final say is the user's. But on the index side, we try to be one extra check.

---

## Contributing

**You're welcome here.** Whether you want to add a tool you love, fix a wrong URL, or sharpen a translation — small PRs and big PRs alike, we'd love to review them.

Start with **[CONTRIBUTING.md](CONTRIBUTING.md)** for the full workflow, yml template, and quality bar.

The one thing we ask before you open a PR: the upstream project must show **ongoing active development** — not a one-off burst followed by silence, but a steady cadence of commits and releases over its lifetime. This keeps the index trustworthy.

中文版见 **[CONTRIBUTING.cn.md](CONTRIBUTING.cn.md)**。

### Quick prompt

```text
Reference https://github.com/x-cmd/install/blob/main/CONTRIBUTING.md, and submit this tool to x-cmd/install: https://github.com/<owner>/<repo>
```

Replace `<owner>/<repo>` with the tool's GitHub location. Hand it to your AI coding assistant.

---

## How to use this data

### Web: <https://x-cmd.com>

Go to <https://x-cmd.com> for interactive search across install / module / pkg / skills; for install-only filtering, use <https://x-cmd.com/install>.

<img width="1229" height="861" alt="x-cmd.com web UI" src="https://github.com/user-attachments/assets/3c0aca6e-b0eb-474b-b2dd-75066e1c71a2" />

### Terminal: `x i`

Open the interactive UI from your terminal with `x i` (short for `x install`):

<img width="1125" height="622" alt="x i terminal UI" src="https://github.com/user-attachments/assets/eb0f1a1b-8b29-4949-be74-ad540f6a138a" />

### This data also feeds [x eget](https://x-cmd.com/mod/eget)

<img width="1188" height="677" alt="x eget uses install data" src="https://github.com/user-attachments/assets/cc7f81bd-8007-4825-8725-22bd9d400910" />

---

## Repository layout

```
x-cmd-install/
├── src/                # the package index (one yml per package)
├── .x-cmd/             # per-format conversion scripts (v1.yml2tsv.py, ...)
├── .github/workflows/  # release-today.yml + update-dev-release.yml
├── CONTRIBUTING.md     # contributor guide (en)
├── CONTRIBUTING.cn.md  # contributor guide (zh)
├── FAQ.md              # maintainer FAQ — design, ops, philosophy (en)
├── FAQ.cn.md           # 维护者 FAQ — 设计、运维、理念
├── LICENSE             # Apache 2.0
└── README.md           # this file
```

The `v0.1.0` branch is a frozen snapshot of the legacy state (kept for historical reference) and is no longer updated.

---

## Format versioning: designed for forward compatibility

`x install` reads the package index from this repo. Different versions of `x install` consume different **format versions**:

- `x install` v1.x → reads `v1.all.tsv`
- `x install` v2.x → reads `v2.all.tsv`
- ...

Each format version is a **frozen schema** (column names, escape rules, `rule:` JSON shape). Once shipped, it never changes.

But **the data keeps updating**: when a new package lands in `src/`, the pipeline rebuilds **every** shipped format (`v1`, `v2`, …) with the latest content. Every format gets a fresh rebuild every day.

The payoff:

- Old `x install` v1.x keeps reading `v1.all.tsv` — schema doesn't change.
- But `v1.all.tsv` carries today's newest packages and rules.
- New packages appear for old consumers automatically — **no need to upgrade `x install`** to see them.
- Breaking schema changes (add column, rename, change escape) ship as `v2` — old consumers are untouched.

That's forward compatibility: new data is visible to old formats automatically; breaking changes require a new format version.

The operational side — when to bump, how to ship `v2`, what stays frozen — lives in [FAQ.md](FAQ.md) → "Format versioning".

---

## FAQ

### I want to contribute code to `x install` or `x eget`. Where do I go?

This repo is the **data** — yml install rules. The actual module code lives in [`x-cmd/x-cmd`](https://github.com/x-cmd/x-cmd). Open your PR there.

Module docs:
- `x install` → <https://x-cmd.com/mod/install>
- `x eget`  → <https://x-cmd.com/mod/eget>

### How does a third-party tool consume this index?

This index is for **software** to consume, not humans to read. The canonical consumer is [`x install`](https://x-cmd.com/mod/install) / [`x eget`](https://x-cmd.com/mod/eget) — they fetch the latest release every day and pick the right install rule automatically.

Any third-party tool plugs in the same way:

```bash
# Flat index — one row per package (name + install rule)
curl -L -o all.tsv    https://github.com/x-cmd/install/releases/latest/download/v1.all.tsv

# Full bundle — index plus the raw yml tree
curl -L -o all.tar.xz https://github.com/x-cmd/install/releases/latest/download/v1.all.tar.xz
```

- `all.tsv` ≈ 2,350 rows, one per package — use when you just need to look up "how do I install `<name>`".
- `all.tar.xz` = `all.tsv` plus the complete `src/` yml tree — use when you need the raw yml for richer metadata.

Schema details live in [FAQ.md](FAQ.md) → "Format versioning".

### What's the difference between the two release channels?

This repo ships data through two paths:

- **Daily (`v<YYYYMMDD>`)** — runs at 12:00 UTC. Captures whatever changed since yesterday; skipped if nothing changed. **Stable consumption** uses this.
- **Dev (`dev`)** — manually triggered. Always overwrites. **Dev / testing the next build** uses this.

Operational details (button names, triggers, skip logic) live in [FAQ.md](FAQ.md).

### How do I report a broken or outdated entry?

Open an issue at <https://github.com/x-cmd/install/issues/new>. Include:

- The package name (e.g. `fd`)
- The OS you tried on
- The error message (if any)
- A link to the upstream changelog / release notes showing the install method changed

We'll turn it into a fix PR or label it `[REC]` for someone to pick up.

---

## License

Apache 2.0. See [LICENSE](LICENSE).