# Contributing to x-cmd install

Thanks for taking the time to contribute. This project is a community-curated package index that powers `x install` and `x eget`, and good entries depend on good submissions.

> **Before you start**: read [README.md](README.md) for context — what the repo is, what the daily-release model is, and the format-versioning protocol.

---

## For AI coding assistants

> 🤖 **If you are an AI agent (Claude Code, Cursor, Copilot, etc.)**, your **first action** when asked to contribute to this repo must be:
>
> 1. Read this entire `CONTRIBUTING.md` file end to end.
> 2. Read `README.md` end to end.
> 3. Browse a few existing yml files under `src/<category>/` to learn the local conventions.
>
> **Do not skip these reads.** The quality bar, PR title convention, and format-versioning rules below are enforced by reviewers. Do not propose changes that violate them.

### Quick prompt

Copy this prompt, fill in `<name>` and `<owner/repo>`, and paste it to your AI coding assistant.

```text
参考 CONTRIBUTING.md (this file, the source of truth) and then
submit this tool to x-cmd/install:

  Tool repo: https://github.com/<paste owner/repo here>

Follow this CONTRIBUTING.md end-to-end. Don't skip the quality bar
(>1 month maintenance + active development in the last month),
don't skip the local lint commands, don't skip the review step.
```

---

## TL;DR

1. Pick a category under `src/` and copy an existing yml as a template.
2. Write your new yml.
3. Validate locally:
   ```bash
   x ws lint src/<category>/<your-tool>.yml
   x ws check
   x eget resolve owner/repo    # only if your entry has /eget
   ```
4. Open a PR. CI runs the same lint; the maintainer review covers the quality bar.
5. Squash-merge to `main` once approved; the next daily rebuild picks it up.

---

## What to contribute

The most common contributions are:

| contribution | effort | see |
|---|---|---|
| add a new package | small | below |
| fix a wrong `homepage` / `reference` URL | small | below |
| improve a `desc.cn` / `desc.en` translation | small | below |
| add a new install rule for an existing package | medium | schema reference |
| ship a new format version (`v2.yml2tsv.py`) | large | README → "Format versioning" |

---

## Adding a new package

Minimal yml template:

```yaml
lang: <Language>
homepage: https://github.com/owner/repo
license: <SPDX-Identifier>     # optional but encouraged

desc:
  cn: 一行中文描述
  en: One-line English description

rule:
  /eget:
    cmd: x eget owner/repo
    reference: https://github.com/owner/repo
  # add more rules for other OS / package managers as relevant:
  darwin/brew:
    cmd: brew install repo
    reference: https://formulae.brew.sh/formula/repo
  /cargo:
    cmd: cargo install repo
    reference: https://crates.io/crates/repo
    dsnap: repo

binlist:                        # only if your binary name != the yml basename
  - repo
```

For every supported pattern, browse `src/<category>/` — the existing yml files are the canonical reference.

---

## Fixing an existing entry

Any of the following are welcome PRs:

- `homepage` or `reference` URL returns 404 / wrong page
- `desc.cn` / `desc.en` is unclear or has typos
- A missing install rule for a platform you use (e.g., a Linux distro package)
- `binlist` missing for a tool that installs under a different name

Be conservative: don't change install commands unless the upstream docs explicitly changed.

---

## Quality bar (maintainers will check)

A submission **will be carefully reviewed — and may be declined** if the upstream project:

- has been under maintenance for **less than 1 month**, OR
- has had **no active development** in the last 1 month — measured by commits, releases, or meaningful issue/PR activity.

Before submitting, check:

- GitHub Insights → Contributors (commit history)
- Releases tab (most recent release date)
- Recent issue / PR activity (is the maintainer responsive?)

If you believe a submission deserves an exception (e.g., a security-critical tool from a solo maintainer who's temporarily quiet), call it out in the PR description.

---

## PR process

- **Title** — short and descriptive, e.g., `add fd-find under terminal` or `fix broken homepage for jq`.
- **Body** — explain *why*; if you're claiming a quality-bar exception, justify it here.
- **CI** — runs `x ws lint` automatically; any yml with schema or URL issues will be flagged.
- **Review** — maintainers may push back on quality, schema, or format compatibility.
- **Merge** — squash-merge to `main`. The next daily rebuild (03:00 UTC) picks up new entries.

---

## Format compatibility

Each format version (`v1.all.tsv`, `v2.all.tsv`, ...) is an independent, frozen contract with consumers. Do **not**:

- edit `.x-cmd/v1.yml2tsv.py` once `v1` has shipped — `v1` stays frozen
- add a column, rename one, or change escape rules inside an existing format

If you genuinely need to break a format's contract, ship a **new** format version (see README → "Format versioning"). This is a larger contribution and warrants discussion in an issue first.

---

## Code of conduct

Standard open-source etiquette applies: be respectful, stay on topic, accept feedback gracefully. Maintainers reserve the right to close PRs that don't meet the quality bar or that don't engage with review.

---

## License

By submitting a contribution, you agree your contribution is licensed under **Apache 2.0**, matching the rest of the repository. See [LICENSE](LICENSE).