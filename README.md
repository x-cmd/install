# x-cmd install

A curated package index that powers [`x install`](https://x-cmd.com) and `x eget`. Each entry is a small YAML file declaring install rules for one tool across the major OS / package-manager combinations.

> 📦 Browse 2,350+ packages across 70+ categories under [`src/`](src).
> 🚀 Daily-rebuilt artifacts (TSV + tar.xz) ship as **immutable `vYYYYMMDD` GitHub Releases** — one per UTC day. Consumers fetch from the latest release (marked "Latest"), **not** from `main`.

---

## Contributing

Want to add a package, fix a wrong URL, or improve a translation? See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the full workflow, yml template, quality bar, and PR process.

Quick check before opening a PR: the upstream project must have **>1 month of maintenance** and **active development within the last month**. See CONTRIBUTING → "Quality bar" for details.

中文版见 **[CONTRIBUTING.cn.md](CONTRIBUTING.cn.md)**。

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
- **The release pattern** — one immutable release per UTC day, named `v<YYYYMMDD>`. Each release is created once and never modified. The most recent release is marked "Latest".
- **The `v0.1.0` branch** — historical snapshot, frozen.

### What happens to old formats

Old format versions are **frozen, not patched**. If a bug is found in v1 output, the fix lives in v2 — v1 stays as it was. This is the whole point of the version boundary: it gives consumers a clean, opt-in upgrade path with no surprise breakage.

---

## License

Apache 2.0. See [LICENSE](LICENSE).