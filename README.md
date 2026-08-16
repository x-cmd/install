# x-cmd install

A curated package index that powers [`x install`](https://x-cmd.com) and `x eget`. Each entry is a small YAML file declaring install rules for one tool across the major OS / package-manager combinations.

> 📦 Browse 2,350+ packages across 70+ categories under [`src/`](src).
> 🚀 Daily-rebuilt artifacts (TSV + tar.xz) ship via the [`v1.0.0`](../../releases/tag/v1.0.0) GitHub Release — consumers fetch from there, **not** from `main`.

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
├── docs/               # schema + category reference
├── .github/workflows/  # build-data.yml — daily rebuild
├── LICENSE             # Apache 2.0
└── README.md           # this file
```

The `v0.1.0` branch is a frozen snapshot of the legacy state (kept for historical reference) and is no longer updated.

---

## License

Apache 2.0. See [LICENSE](LICENSE).