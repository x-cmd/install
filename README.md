# x-cmd install

A curated package index that powers [`x install`](https://x-cmd.com) and `x eget`. Each entry is a small YAML file declaring install rules for one tool across the major OS / package-manager combinations.

> 📦 Browse 2,350+ packages across 70+ categories under [`src/`](src).
> 🚀 Daily-rebuilt artifacts (TSV + tar.xz) ship as **immutable `vYYYYMMDD` GitHub Releases** — one per UTC day. Consumers fetch from the latest release (marked "Latest"), **not** from `main`.

---

## How to add a package

1. **Pick a category** under `src/` (categories are documented at the top of each subfolder — see existing entries as templates).
2. **Create `src/<category>/<your-tool>.yml`** with a minimal entry:

   ```yaml
   lang: Rust
   homepage: https://github.com/owner/repo
   license: MIT

   desc:
     cn: 一行中文描述
     en: One-line English description

   rule:
     /eget:
       cmd: x eget owner/repo
       reference: https://github.com/owner/repo
     darwin/brew:
       cmd: brew install repo
       reference: https://formulae.brew.sh/formula/repo
     /cargo:
       cmd: cargo install repo
       reference: https://crates.io/crates/repo
       dsnap: repo

   binlist:
     - repo
   ```

3. **Validate locally:**

   ```bash
   x ws lint src/<category>/<your-tool>.yml   # schema + URL sanity
   x ws check                                  # name-conflict sweep
   x eget resolve owner/repo                   # verify /eget rule
   ```

4. **Open a PR.** CI runs the same lint; broken rules or missing fields will be flagged in review.

For the full schema (all fields, multi-rule syntax, language-package-manager `dsnap`, optional `binlist`, etc.), browse existing yml files in `src/<category>/` — they show every supported pattern.

---

## Quality criteria

A package index is only as useful as the packages it lists. We hold this index to a high bar, and a submission **will be carefully reviewed — and may be declined** if the upstream project:

- has been under maintenance for **less than 1 month**, OR
- has had **no active development** in the last 1 month — measured by commits, releases, or meaningful issue/PR activity.

How to check before submitting:

- **Commit history** — Insights → Contributors on the project's GitHub.
- **Release cadence** — most recent release date on the Releases tab.
- **Issue / PR responsiveness** — are maintainers still answering?

Rationale: dead, abandoned, or never-released projects rot the index, waste users' install time, and pull in security risk. A mature install entry should outlive its first commit by a wide margin.

If you believe a submission deserves an exception (e.g., a security-critical tool from a solo maintainer who's temporarily quiet), call it out in the PR description — explain why it should be included despite the flag.

---

## Repository layout

```
x-cmd-install/
├── src/                # the package index (one yml per package)
├── .x-cmd/             # per-format conversion scripts (v1.yml2tsv.py, ...)
├── .github/workflows/  # build-data.yml — daily rebuild
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