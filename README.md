# x-cmd install

Three things to keep straight:

1. **[x-cmd](https://x-cmd.com)** — a POSIX shell superpowers toolkit. The thing you install and run.
2. **`x install`** / **`x eget`** — two commands inside x-cmd that resolve "how do I get tool X onto my machine?". `x install` picks the best available install rule; `x eget` fetches a prebuilt binary from a GitHub release. (See [`x-cmd.com/mod/install`](https://x-cmd.com/mod/install) and [`x-cmd.com/mod/eget`](https://x-cmd.com/mod/eget).)
3. **This repository (`x-cmd-install/install`)** — the **data** those commands consume. Not the code, not the modules — just the curated YAML index: for each of 2,350+ tools, the install rules per OS / per package manager.

In short: x-cmd has the brain; this repo has the lookup table.

> 📦 **2,350+ packages** across 70+ categories under [`src/`](src).
> 🚀 Daily-rebuilt artifacts (TSV + tar.xz) ship as **immutable `vYYYYMMDD` GitHub Releases** at 12:00 UTC (= 20:00 Asia/Shanghai). Consumers fetch from the latest release (marked "Latest"), **not** from `main`.

---

## Contributing

Want to add a package, fix a wrong URL, or improve a translation? See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the full workflow, yml template, and quality bar.

Quick check before opening a PR: the upstream project must have **>1 month of maintenance** and **active development within the last month**. See CONTRIBUTING → "Quality bar" for details.

中文版见 **[CONTRIBUTING.cn.md](CONTRIBUTING.cn.md)**。

### Quick prompt

Copy this prompt, paste the tool's GitHub URL, and hand it to your AI coding assistant.

```text
参考 https://github.com/x-cmd/install/blob/main/CONTRIBUTING.md ，并向 x-cmd/install 仓库提交新软件：

  https://github.com/<在这里贴 owner/repo>
```

---

## Repository layout

```
x-cmd-install/
├── src/                # the package index (one yml per package)
├── .x-cmd/             # per-format conversion scripts (v1.yml2tsv.py, ...)
├── .github/workflows/  # release-today.yml + update-dev-release.yml
├── CONTRIBUTING.md     # contributor guide (en)
├── CONTRIBUTING.cn.md  # contributor guide (zh)
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

### How do I consume the package index?

Fetch from the latest GitHub Release:
```bash
curl -L -o all.tsv    https://github.com/x-cmd/install/releases/latest/download/v1.all.tsv
curl -L -o all.tar.xz https://github.com/x-cmd/install/releases/latest/download/v1.all.tar.xz
```
`all.tsv` is the index; `all.tar.xz` bundles the index plus the full `src/` yml tree.

### What's the difference between the two release channels?

There are two workflow buttons in the Actions tab:

- **Release today** — daily cron (12:00 UTC = 20:00 Asia/Shanghai) + manual; creates/replaces `v<YYYYMMDD>` (marked "Latest"). Identical-data days are skipped (no new tag).
- **Update dev release** — manual only; replaces the `dev` release assets (marked "Pre-release", never overrides Latest).

For stable data, use the latest `v<YYYYMMDD>`. For testing the next build, use `dev`.

---

## License

Apache 2.0. See [LICENSE](LICENSE).