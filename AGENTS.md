# AGENTS.md — how agents work with `x-cmd/install`

This repo is the **canonical install database** for `x install` /
`x eget` — see `README.md` for the user-facing overview. This
file is the agent-facing equivalent: it tells you which repos
exist in this org, who owns what, and what conventions to follow.

## Org layout (x-cmd)

The repos you will see most often:

- **`x-cmd/install`** *(this repo)* — install database. One YAML
  file per software under `src/<category>/<name>.yml`. Editing
  here controls what `x install <name>` does. **Not** a fork.
- **`x-cmd-install/<software>`** — data collector for one piece
  of software. **Not** a fork of upstream source code; the
  scheduled GitHub Action in `.github/workflows/card.yml`
  queries the upstream for metadata (release info, OpenSSF score,
  repology status, contributor activity, etc.) and writes the
  result to `data/<YYMMDD>.yml` + `README.md` + `README.cn.md`.
  See `x-cmd-install-stat` for what consumes the output.
- **`x-cmd-install/x-cmd-install-stat`** — aggregator. Walks every
  collector, fetches their freshest `data/card/<YYMMDD>.yml`,
  and writes `stat/<software>/latest.{card,report}.{yml,json}`.
  The website reads from this repo's `stat/` tree.
- **`x-cmd-install/mneme`** — *private* internal notes for the
  x-cmd team. Not a place for public-facing docs; private because
  it tracks organizational quirks, past mistakes, and operational
  details that should not leak. **Agents contributing to x-cmd
  publicly should not write to it.**

## Reading path (where does data come from?)

    upstream GitHub repo (real source code, e.g. jqlang/jq)
        ↓  (queried by the collector action — NOT forked)
    x-cmd-install/<software>     ← collector writes data/*.yml + README.{md,cn.md}
        ↓  (read by sync.sh)
    x-cmd-install/x-cmd-install-stat  ← aggregator, stat/<software>/...
        ↓  (consumed by)
    cn.x-cmd.com/install/<software>

If a piece of software shows up in `x install <name>` but the
website is blank, the collector for `x-cmd-install/<name>` is
missing or stale — fix it there, not in `x-cmd/install`.

## How to add a new piece of software

1. **Add a yml file** under `src/<category>/<name>.yml` in this repo.
   Use an existing entry as a template; see `src/scm/git.yml` for
   a canonical example.
2. **Create a collector** at `x-cmd-install/<name>`. Run the
   repo setup script: `./.x-cmd/bulk-create-repos.sh --input <tsv>`
   where `<tsv>` is `ownerrepo\trepo\tdesc` per line. This uses
   `gh repo create` (not `gh repo fork`) — collectors are empty
   repos seeded with a README, then populated with:
   - `.x-cmd/fskv/ownerrepo` containing `<upstream_owner>/<upstream_repo>`,
   - `.github/workflows/card.yml` calling
     `x-cmd-install/x-cmd-install-action@main`.
3. The collector's first scheduled run writes `data/card/<YYMMDD>.yml`
   + `README.md` + `README.cn.md` automatically. Within a day the
   website picks it up via the aggregator.

## Conventions in `src/<category>/<name>.yml`

- Each entry MUST set `lang`, `homepage`, `license`.
- `x.source` and/or `x.eget` MUST be set if the install path is
  upstream GitHub. Format: `https://github.com/<owner>/<repo>`.
- `desc.cn` and `desc.en` are required.
- `binlist` is the list of binary names produced by the install.
- `footprint.behavior` (network / fs) and `footprint.resource`
  (disk / memory / cpu) are checked at install time and rate the
  install on the website. See the schema in `mneme/profile/`.

## Conventions in the collector

- Mirror name in `x-cmd-install/` matches the upstream GitHub repo
  name, case-preserving (`1Panel`, `jq`, `FFmpeg`, `kotlin`).
- `fskv/scorecard_ownerrepo` — if the upstream was renamed and
  OpenSSF scorecard is tracked under a different path, set this.
- `fskv/repology_name` — opt-in: if the project key on repology
  differs from the bare repo name (e.g. `yq` → `yq-mikefarah`),
  write the repology project key here. If unset, repology data
  is not fetched.
- Do NOT `gh repo fork` upstream source code into a collector.
  Collectors are intentionally empty repos — the action writes
  metadata, not source.

## When you (the agent) make changes

- `x-cmd/install` is a normal public contribution. PRs welcome
  for new yml entries or fixes to existing ones. Workflow: fork
  → branch → change → PR. Same as any other repo.
- `x-cmd-install/<software>` collectors: most updates are
  automatic (the action runs daily). To force a refresh, dispatch
  the `card.yml` workflow. Manual edits to `data/*.yml` will be
  overwritten on the next run — fix the action instead.
- `x-cmd-install/x-cmd-install-stat`: PRs welcome for sync.sh
  improvements, aggregator fixes, new analysis scripts. Don't edit
  `stat/` directly — it's auto-regenerated from collectors.
- `x-cmd-install/mneme`: **private, internal-only.** Not for
  agent PRs. Use only for x-cmd team-internal context.

## Skills

This repo's `.x-cmd/skill/` (or whatever path the team maintains)
will hold agent skills for working with the install database —
  things like "how to add a new entry", "how to validate yml
  schema", "how to debug a missing collector". Check there first
  before improvising.
