# x-cmd install

A curated package index that powers [`x install`](https://x-cmd.com) and `x eget`. Each entry is a small YAML file declaring install rules for one tool across the major OS / package-manager combinations.

> 📦 Browse 2,350+ packages across 70+ categories under [`src/`](src).
> 🚀 Daily-rebuilt artifacts (TSV + tar.xz) ship as **immutable `vYYYYMMDD` GitHub Releases** — one per UTC day at 12:00 UTC (= 20:00 Asia/Shanghai). Consumers fetch from the latest release (marked "Latest"), **not** from `main`.
> 🧪 A **`dev` release** is updated on every manual trigger of the `Release dev data` workflow — a moving build target for testing. Marked "Pre-release", so it never overrides the daily `Latest` release.
>
> Two workflow buttons in the Actions tab:
> - **Release today** — daily cron + manual; creates/replaces `v<YYYYMMDD>` (marked Latest).
> - **Update dev release** — manual only; replaces the `dev` release assets (Pre-release).

---

## Contributing

Want to add a package, fix a wrong URL, or improve a translation? See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the full workflow, yml template, quality bar, and PR process.

Quick check before opening a PR: the upstream project must have **>1 month of maintenance** and **active development within the last month**. See CONTRIBUTING → "Quality bar" for details.

中文版见 **[CONTRIBUTING.cn.md](CONTRIBUTING.cn.md)**。

### Quick prompt

Copy this prompt, fill in `<name>` and `<owner/repo>`, and paste it to your AI coding assistant. It will scaffold the whole contribution for you.

```text
I want to add a new package to the x-cmd install index.

Tool name:       <name>
Upstream repo:   https://github.com/<owner/repo>

Please:
1. **Before anything else**: read CONTRIBUTING.md and README.md
   **in full** — they are the source of truth for this repo. Do not
   skip the reads; the quality bar, PR title convention, and
   format-versioning rules are enforced by reviewers.
2. Pick the right category under src/ (existing yml files in nearby
   folders are templates — match their style).
3. Write src/<category>/<name>.yml with at minimum:
     - lang
     - homepage
     - desc.cn / desc.en (one line each)
     - rule with /eget pointing at <owner/repo>
       (plus any apt/brew/cargo/pip rules you find on the project's docs)
4. Validate locally:
     x ws lint src/<category>/<name>.yml
     x ws check
     x eget resolve <owner/repo>
5. Commit on a new branch, push, and open a PR titled
   `add <name>`.
6. Stop and wait for me to review the diff before merging.

Note: the upstream project must have >1 month of maintenance AND
active development in the last month. If it doesn't, justify the
exception in the PR description.
```

---

## Repository layout

```
x-cmd-install/
├── src/                # the package index (one yml per package)
├── .x-cmd/             # per-format conversion scripts (v1.yml2tsv.py, ...)
├── .github/workflows/  # build-data.yml — daily rebuild
├── CONTRIBUTING.md     # contributor guide (en)
├── CONTRIBUTING.cn.md  # contributor guide (zh)
├── LICENSE             # Apache 2.0
└── README.md           # this file
```

The `v0.1.0` branch is a frozen snapshot of the legacy state (kept for historical reference) and is no longer updated.

---

## Format versioning

The pipeline ships **versioned contracts** — `v1.all.tsv` / `v1.all.tar.xz` is the v1 contract with consumers; `v2.all.tsv` / `v2.all.tar.xz` would be v2's. Each version is independently frozen once shipped.

Breaking changes don't modify an existing version — they ship as a new version (v2, v3, ...). The old version keeps packaging forever, untouched, so its existing consumers never break. This section is the protocol for that.

The pipeline is built around **multi-format continuous packaging**: every format version that has ever shipped keeps getting rebuilt and uploaded every day, side by side. New formats are added; old ones never get edited.

### When a bump is needed

| change | bump? |
|---|---|
| add a column to the TSV | yes (new major format) |
| rename or remove a column | yes |
| change TSV escape rules | yes |
| restructure the inline `rule:` JSON shape | yes |
| add a new optional field inside `rule:` JSON | **no** — backward-compat within the format |
| update `binlist` / `desc.cn` values across many yml | **no** — data only |
| change the yml schema under `src/` | yes (the input schema is its own contract) |

### How to ship a new format (e.g., `v2`)

1. **Write `.x-cmd/v2.yml2tsv.py`** — mirror v1's structure with the new schema. Each format gets its own script.
2. **Open a PR.** That's it. The workflow globs `.x-cmd/v*.yml2tsv.py` on every run, picks up v2 automatically, and uploads `v2.all.tsv` + `v2.all.tar.xz` alongside the existing v1 assets.
3. **Update this section of the README** so future contributors know v2 exists.

After merge, the release carries `v1.all.tsv` + `v1.all.tar.xz` + `v2.all.tsv` + `v2.all.tar.xz`. Consumers using v1 see no change. Consumers wanting v2 fetch the new assets.

### What never changes

- **The yml schema under `src/`** — input is its own stable contract; output format is the thing that moves.
- **The release pattern** — one immutable release per UTC day, named `v<YYYYMMDD>`, built at 12:00 UTC (= 20:00 Asia/Shanghai). Each release is created once and never modified. The most recent release is marked "Latest".
- **The `dev` release** — a single persistent release that gets its assets replaced on every manual workflow run. Marked "Pre-release" so it never overrides Latest.
- **The `v0.1.0` branch** — historical snapshot, frozen.

### What happens to old formats

Old format versions are **frozen, not patched**. If a bug is found in v1 output, the fix lives in v2 — v1 stays as it was. This is the whole point of the version boundary: it gives consumers a clean, opt-in upgrade path with no surprise breakage.

---

## FAQ

### I want to contribute code to `x install`. Where do I go?

This repository contains the **data** — yml files declaring install rules for each package. The actual `x install` module code lives in [`x-cmd/x-cmd`](https://github.com/x-cmd/x-cmd); open your PR there.

For module documentation, see <https://x-cmd.com/mod/install>.

### How do I consume the package index?

Fetch the latest release's assets from GitHub Releases:
```bash
curl -L -o all.tsv  https://github.com/x-cmd/install/releases/latest/download/v1.all.tsv
curl -L -o all.tar.xz https://github.com/x-cmd/install/releases/latest/download/v1.all.tar.xz
```
`all.tsv` is the index; `all.tar.xz` bundles the index plus the full `src/` yml tree.

### What's the difference between the `v<YYYYMMDD>` and `dev` releases?

- `v<YYYYMMDD>` — daily immutable snapshot, marked "Latest". Created at 12:00 UTC (20:00 Asia/Shanghai) and on manual trigger. Identical-data days are skipped (no new tag).
- `dev` — replaceable pre-release, updated on every manual run of the "Update dev release" workflow.

For stable data, use the latest `v<YYYYMMDD>`. For testing the next build, use `dev`.

---

## License

Apache 2.0. See [LICENSE](LICENSE).