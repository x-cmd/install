# FAQ

> For the **user-facing** FAQ (where to contribute, how to consume, what
> the release channels are), see [README.md](README.md) → "FAQ".
>
> This document is for **maintainers** — design rationale, operational
> details, philosophy. Skip if you're just using the data.

---

## Design

### Why two separate workflows (release-today + update-dev-release)?

Single workflow with conditional logic (one button that picks daily vs dev) was tried first. It muddled two distinct intents — "publish today's snapshot" and "smash the dev release" — into one button, which makes the Actions tab ambiguous. Splitting them gives each intent its own button, its own history, its own failure surface.

### Why is `v1.yml2tsv.py` output sorted by `(category, name)`?

`as_completed()` yields futures in random order, so a naive build produces a byte-different TSV every run even when the input is identical. That breaks the daily skip-if-unchanged check (`diff` always reports a difference). Sorting by `(category, name)` makes the output byte-stable so `diff` actually catches real changes.

### Why are format versions frozen instead of patched?

A format version is a **contract** with consumers (`x install`/`x eget`). Editing v1's output to fix a bug breaks every consumer that already parsed v1 output. The version boundary exists to give consumers a clean, opt-in upgrade path: stay on v1 forever, or jump to v2. Frozen means frozen — even legitimate bug fixes live in the next version.

### Why one immutable release per UTC day (`v<YYYYMMDD>`) at 12:00 UTC?

- **One per day** — human-readable tag (`v20260817`) doubles as a release pointer; `git clone --branch v20260817 --depth=1` gives a snapshot.
- **Immutable** — each day's data is the data; if a new commit accidentally pushes bad output, fixing it means a new release (`v20260817a`), not editing in place.
- **12:00 UTC = 20:00 Asia/Shanghai** — non-Western working hours, low traffic, gives late-day PRs time to land in the build.
- **Skip if unchanged** — the workflow checks `v<YESTERDAY>`'s `v1.all.tsv` against the new build; if they match, no new tag. Keeps the tag list from filling with empty duplicates.

### Why `dev` as a replaceable pre-release?

`dev` is a moving target for testing — devs run `Update dev release` whenever they want a fresh build on top of `main`. It must not steal "Latest" from the daily releases, so it's marked pre-release. Asset overwrite semantics are fine because `dev` consumers are expected to re-fetch.

### Why is `release-data` a composite action instead of inline workflow steps?

Build + upload logic is shared between the daily and dev workflows. Inlining it duplicates ~50 lines; a composite action (`.github/actions/release-data/action.yml`) keeps it in one place and lets new release channels (e.g., `rc`) be added as one-line workflow calls. Same reason the yml scripts live in `.x-cmd/` instead of each workflow.

---

## Operations

### How do I manually trigger each workflow?

| intent | workflow | button | behavior |
|---|---|---|---|
| rebuild today's daily release | `release-today.yml` | "Release today" | creates/replaces `v<TODAY>` (skipped if identical to yesterday) |
| refresh dev release | `update-dev-release.yml` | "Update dev release" | overwrites `dev` assets |

Both are also auto-triggered where appropriate (`release-today` via cron 12:00 UTC; `update-dev-release` is manual-only).

### How does the skip-if-unchanged check actually work?

`release-today.yml` passes `if_changed_since: v<YESTERDAY>` to `release-data`. The action:
1. builds all `v*.all.tsv`
2. runs `gh release download v<YESTERDAY> --pattern "v*.all.tsv"` to /tmp
3. `diff -q` each today's `v<N>.all.tsv` against the reference
4. if **all** match (or reference doesn't exist) → `exit 0`, upload step skipped, no new tag
5. if **any** differs (or new format added) → upload today's full set

Reference missing is treated as "changed" — first-ever run, or cron disabled for a while, both should produce a release.

### What if the daily cron fails?

The cron is `0 12 * * *`. Failures show up as red runs in Actions. Most common causes:
- `yq` download URL changed → update the `wget` URL in `release-data/action.yml`
- new yml file has bad syntax → fix the yml, manually re-run `release-today`
- release-data action has a bug → fix it, push, manually re-run

A failed run does **not** leave a partial release — the softprops upload step is the last one, so if it fails, there's nothing to clean up.

### How do I ship a new format version (`v2`)?

See README → "Format versioning → How to ship a new format". Summary: drop `.x-cmd/v2.yml2tsv.py`, add `2` to `.format-versions-supported` (well, that file got removed; now the workflow globs `v*.yml2tsv.py` automatically), bump `.format-version` to `2`, open PR. The workflow picks up `v2` on the next run without further config.

### What's the role of the `x-cmd-install/x-cmd-install` (mneme) repo?

It's the **internal archive** for this project — design drafts, operational logs, vendor sources, eget algorithm scratch work. Not for public consumption. Public-facing work happens in this repo (`x-cmd-install/install`); internal/strategic thinking stays in mneme. The boundary prevents internal R&D from leaking into consumer-facing artifacts.

### Why no CI lint on PRs yet?

The plan is in [issue #2](https://github.com/x-cmd/install/issues/2) (`Add eget rule linting for /eget entries in src/ yml`). Deferred — current PRs are reviewed manually and the volume is manageable. Add a CI job once contribution volume justifies it.

---

## Philosophy

### Why 78 `[REC]` issues in this repo?

They were moved here from `x-cmd/x-cmd` in one batch — the x-cmd monorepo's `[REC]` label historically meant "install recipe request" (one issue per tool to add). The split was overdue: install metadata is data, not module code; the public repo is the right home. The migration was a `gh issue transfer` per issue, with state preserved (open/closed both moved).

### Why are release names minimal (`v20260816`, not `v20260816 — x-cmd install data`)?

The tag and the release name now match exactly. Reason: the `— x-cmd install data` suffix was redundant — every release in this repo is x-cmd install data. Stripping it makes the Releases page scan-friendly (you can pick the date out of the title at a glance) and avoids drift if anyone ever forgets to update the suffix after renaming the project.

### Why is this repo metadata-only?

`x install` / `x eget` themselves are **code** in [`x-cmd/x-cmd`](https://github.com/x-cmd/x-cmd). The install index is **data** — one yml per package. Splitting data from code lets:
- community PRs be reviewed against a clear schema (yml) without rebuilding x-cmd
- daily rebuilds churn 2,350+ yml files without touching the module
- consumers fetch the data directly without cloning the whole module

### Why are there no PR / issue templates?

Templates bias contributions toward the template's idea of a good contribution. For an index where most PRs are "add one yml for tool X", a template adds friction without adding signal. The PR title convention (`add <name>`, `fix broken homepage for <pkg>`) is documented in CONTRIBUTING.md; that's enough structure.