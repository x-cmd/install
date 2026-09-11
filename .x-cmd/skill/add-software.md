# Add a new piece of software to `x install`

## When to use
A user reports that `x install <name>` doesn't work, OR you spot
a piece of software on GitHub that has no entry in `x-cmd/install`.

## What you can / cannot do
- You CAN add a yml entry under `src/<category>/<name>.yml`.
- You CAN create the matching collector `x-cmd-install/<name>`.
- You CANNOT push source code into the collector (it's metadata
  only — see AGENTS.md for what a collector actually is).

## Steps
1. Locate or invent the `src/<category>/` directory — common
   ones are `scm/`, `app/`, `cli/`, `dev/`, `tools/`,
   `runtime/`, `virtualization/`, `security/`, `net/`, `data/`,
   `system/`, `media/`, `ai/`.
2. Pick a name matching the upstream GitHub repo name, case-
   preserving (`jq`, `1Panel`, `FFmpeg`).
3. Copy an existing yml as template (e.g. `src/scm/git.yml`) and
   fill in: `lang`, `homepage`, `license`, `desc.cn`, `desc.en`,
   `x.source` / `x.eget`, `binlist`, `rule.<cmd>` blocks for each
   install method, `footprint` block.
4. Validate the yml against `.x-cmd/install-yml-check.schema.json`.
5. Create the collector by adding a line `<upstream_owner>/<repo>  <repo>  <desc>` to a TSV and running
   `./.x-cmd/bulk-create-repos.sh --input <tsv>` from the
   `x-cmd-install-stat` checkout. **Do not `gh repo fork`** — use
   `gh repo create` (which the script does internally).
6. After the script seeds the collector, the fskv + workflow
   files are committed. To override the cron schedule, edit the
   workflow file.

## Gotchas
- The collector cron is minutes-of-the-hour; pick a unique
  minute per collector to avoid GitHub Actions queueing.
- If `x.source` points to a private or unarchived repo, the
  collector will fail every run. Verify forkability before
  creating the collector.
