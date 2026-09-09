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

Copy this prompt, fill in `<owner/repo>` (the repo you want to add), and paste it to your AI coding assistant.

```text
Following https://github.com/x-cmd/install/blob/main/CONTRIBUTING.md , submit a new package to the x-cmd/install repo:

  https://github.com/<paste owner/repo here>
```

---

## TL;DR

1. Pick a category under `src/` and copy an existing yml as a template.
2. Write your new yml.
3. Validate locally:
   ```bash
   x ws lint src/<category>/<your-tool>.yml
   x ws check
   x eget use owner/repo        # only if your entry has /eget
   ```
4. Open a PR. CI runs the same lint; the maintainer review covers the quality bar.
5. Squash-merge to `main` once approved; the next daily rebuild (03:00 UTC) picks it up.

---

## What to contribute

The most common contributions are:

| contribution | effort | see |
|---|---|---|
| add a new package | small | below |
| fix a wrong `homepage` / `reference` URL | small | below |
| improve a `desc.cn` / `desc.en` translation | small | below |
| add a new install rule for an existing package | medium | [schema](.vscode/install.schema.json) |
| ship a new format version (`v2.yml2tsv.py`) | large | [README → Format versioning](README.md#format-versioning-designed-for-forward-compatibility) |

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

x:
  source: https://github.com/owner/repo
  eget: https://github.com/owner/repo

rule:
  /eget:
    cmd: x eget use owner/repo
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

# Optional but recommended — fill the footprint block. See the
# "Footprint block" section below for the full schema.
footprint:
  behavior:
    runtime:
      type: cli                   # cli|tui|gui|daemon|server|lib|...
    network:
      listen: localhost           # none|localhost|lan|internet
      connect:
        localhost: true
        lan: true
        internet: true
    filesystem:
      read:
        desc:
          cn: 读取配置文件
          en: Reads config files
  resource:
    disk:
      size:
        install:
          estimate: 30 MB
          rating: 2
          desc:
            cn: 安装 30 MB
            en: 30 MB install
    memory:
      idle:
        estimate: 50 MB
        desc:
          cn: 50 MB
          en: 50 MB
    cpu:
      workload: ['compute']
      processes: 1
      peak:
        rating: 2
        desc:
          cn: 低
          en: Low
```

If you're unsure of any values, run the harness from `x-cmd-install/mneme`
to measure them for real. If you don't have time, leave reasonable
estimates — they get a `# complicated` marker for later review.

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

A submission **will be carefully reviewed — and may be declined** if the upstream project doesn't show **ongoing active development** — i.e., not a one-off burst followed by silence, but a steady cadence of commits, releases, or meaningful issue/PR activity over its lifetime.

Before submitting, check:

- GitHub Insights → Contributors (commit cadence over the project's lifetime)
- Releases tab (are releases happening on a regular schedule?)
- Recent issue / PR activity (is the maintainer still responsive?)

If you believe a submission deserves an exception (e.g., a security-critical tool from a solo maintainer who's temporarily quiet, or a long-running stable project with infrequent but real releases), call it out in the PR description.

## What we reject

We love interesting new tools, but this isn't a marketing page. The following will be declined (and existing entries removed) without further discussion:

- Tools that engage in **malicious behavior**
- Tools that **collect user privacy** without clear, prominent disclosure
- Tools that **hide what they do** — undocumented network calls, hidden background processes, obfuscated payloads

`x install` runs on the user's machine, so the final say is the user's. But on the index side, we try to be one extra check.

---

## Footprint block

Each entry may include an optional `footprint:` block describing what the
binary does on the user's machine: disk usage, memory cost, CPU workload,
network behavior, and filesystem access. This block powers the `x cmd --footprint`
display in `--help` output, so users can audit the cost before installing.

### Schema

The block has a strict JSON Schema — see [`.vscode/install.schema.json`](.vscode/install.schema.json).
You can validate any yml locally with:

```bash
x ajv -s .vscode/install.schema.json -d src/<category>/<name>.yml
```

CI also runs this on every PR and blocks merges that fail it.

### Field reference

```yaml
footprint:
  behavior:
    runtime:
      type: cli                      # cli|tui|gui|daemon|server|lib|library|plugin|interactive|oneshot|script|wrapper
                                     # also accepts an array of any of the above
    network:
      listen: localhost              # none | localhost | lan | internet — broadest surface it BINDS
      connect:                       # independent flags for outbound destinations
        localhost: true|false
        lan:       true|false         # RFC1918 (10/8, 172.16/12, 192.168/16)
        internet:  true|false         # public IPs / DNS names
    filesystem:
      read:
        desc: { cn: ..., en: ... }
        sensitive: []                 # globs of files that count as sensitive (e.g. ~/.ssh/id_*)
      write:
        desc: { cn: ..., en: ... }
  resource:
    disk:
      size:
        install:                     # REQUIRED — total install footprint after extraction
          estimate: 30 MB
          rating: 1                   # 1=Negligible <10MB, 2=Low 10-50MB, 3=Moderate 50-200MB,
                                       # 4=Heavy 200MB-1GB, 5=Very heavy >1GB
          desc: { cn: 安装 30 MB, en: 30 MB install }
        download:                    # OPTIONAL — compressed archive size
          estimate: 12 MB
          desc: { cn: 约 12 MB 下载, en: ~12 MB download }
        growth:                      # OPTIONAL — runtime data growth (logs, cache, etc.)
          desc: { cn: ..., en: ... }
      paths:
        data:    ["~/.cache/foo/"]    # runtime persistent data
        config:  ["~/.config/foo/"]   # config files
        cache:   ["~/.cache/foo/"]    # optional — disk caches
    memory:
      idle:
        estimate: 50 MB
        desc: { cn: 50 MB, en: 50 MB }
      peak:                          # OPTIONAL — under load
        estimate: 200 MB
        desc: { cn: 200 MB, en: 200 MB }
    cpu:
      workload: ['compute']          # compute|io|network|memory|gpu
      processes: 1
      idle:
        rating: 0                    # 0 = idle/none, 1..5 = active
        desc: { cn: 几乎为零, en: Near-zero }
      peak:
        rating: 2                    # 1=Sub-ms, 2=Low, 3=Moderate, 4=Heavy, 5=Sustained
        desc: { cn: 低, en: Low }
  platform:                          # OPTIONAL — per-OS support levels
    win:    full|partial|none
    linux:  full|partial|none
    darwin: full|partial|none
```

### Network: why `listen` is an enum but `connect` is a list

The two directions have **opposite** security stances:

- **Listening** = others can probe you (inbound attack surface). A binary
  that binds `0.0.0.0:443` inherently listens on **every** interface —
  localhost, LAN, internet. There is no middle ground, so `listen` is a
  single enum picking the broadest surface.
- **Connecting** = you reach out (outbound leak vector). A tool may be
  *permitted* to reach the public internet but *forbidden* to touch private
  LAN addresses (or vice versa). Forcing a single enum would lose this
  policy distinction, so `connect` is independent flags.

Concrete examples:

| Tool | listen | connect |
|---|---|---|
| `curl`, `gh`, `httpie` | none | `internet: true` (implies `lan: true` per default rule) |
| `fzf --listen` | localhost | `localhost: true` |
| `ngrok` | localhost | `internet: true` |
| `syncthing` | internet | `internet: true, lan: true` |
| `nmap` | none | `lan: true` (LAN scanner; LAN keywords override default) |
| `mosquitto` broker | lan | none |
| `jq`, `fd`, `bat` | none | all false |

**Default rule for `connect.lan`**: follows `connect.internet` (HTTP/TCP
clients can hit RFC1918 just as easily as public IPs). Override to `true`
when the yml body contains LAN-only keywords (`sync`, `p2p`, `smb`,
`nfs`, `mDNS`, `syncthing`, `nmap`, `mosquitto`, `multicast`, `ssdp`,
`upnp`, ...) AND `connect.internet: false`.

### Two markers above `footprint:`

Lines```yaml
# already profiled           # measured (real numbers from ubuntu container harness)
footprint:
  ...
```

```yaml
# complicated                # estimated from x-cmd-install-stat or lang: default
footprint:
  ...
```

These markers tell the profiling pipeline which entries to skip (CI re-profiling
won't re-measure a `# already profiled` entry). To re-profile, delete the
comment line and re-run the harness — see the **Maintenance** section below.

### Estimating without measurement

If you don't have time to run the container harness, you can fill the
block from heuristics alone:

- **disk.size.install.estimate**: pick the largest single asset on the
  latest release page. The compressed archive name usually shows size
  (e.g. `v1.2.3-linux-amd64.tar.gz (12 MB)`).
- **memory.idle.estimate**: 5 MB is a safe default for compiled CLIs,
  10 MB for interpreted ones, 50 MB+ for JVM/.NET runtimes.
- **cpu.peak.rating**: 1 for `--version`-fast tools, 2 for typical CLI
  invocations, 3+ for long-running watchers / TUIs.
- **network**: read the README — does it bind any port? Does it fetch
  remote assets? Does it sync via mDNS / BitTorrent / SMB?

Mark these as `# complicated`. They get a low-confidence marker and are
flagged for a later round of measurement.

---

## Maintenance

The `footprint:` block is a high-churn surface — estimates are
mechanically computed and many will be wrong. Here's how the repo is
maintained:

### Tooling (under `.x-cmd/`)

| Script | Purpose |
|---|---|
| `install-network-migrate` | Migrate old `local/internet` schema to `listen/connect`. Idempotent — safe to re-run. |
| `install-download-check` | Read-only test that scans every yml for `install < download` violations. Expected exit code 0. |
| `install-yml-check.schema.json` | Mirror of `.vscode/install.schema.json` for offline `x ajv` runs. |

### Profiling pipeline

The measurement harness lives at **[x-cmd-install/mneme](https://github.com/x-cmd-install/mneme)**:

```bash
# Install the skill locally
git clone https://github.com/x-cmd-install/mneme ~/.x-repo/github.com/x-cmd-install/mneme

# Profile one entry
~/.x-repo/github.com/x-cmd-install/mneme/profile/scripts/measure.sh jqlang/jq

# Profile via yml path (respects # already profiled marker)
~/.x-repo/github.com/x-cmd-install/mneme/profile/scripts/measure.sh --yml path/to/entry.yml
```

What the harness does:

1. `eget` pulls the Linux/amd64 (or x86_64-unknown-linux-gnu) asset for the
   repo, falling back to a direct GitHub API call when eget rate-limits.
2. Extracts (`tar`, `unzip`, `ar x … tar`, or copy raw).
3. Measures:
   - `dl_human` — size of the downloaded file (compressed archive)
   - `disk_human` — size of all extracted files
   - `rss_avg_kb` / `rss_max_kb` — RSS samples inside an Ubuntu 24.04
     container running the binary across 8 invocations
   - `cpu_jiffies_peak` — peak CPU time in jiffies
4. Emits parseable `key=value` lines that apply scripts can patch into
   the yml.

The harness uses **aliyun mirrors** for apt (CN-friendly) and runs in an
isolated bind-mount (`/app` read-only).

### Workflow

```
[ agent / harness ]  ──▶  candidate values (key=value lines)
                              │
                              ▼
[ human reviewer ]   ──▶  verified values + `# already profiled` marker
                              │
                              ▼
[ pull request   ]    ──▶  source of truth in install/src
```

See [`rating.md`](https://github.com/x-cmd-install/mneme/blob/main/profile/rating.md)
§ 8 for the canonical workflow.

### CI checklist (recommended)

Add these to your fork's CI:

```bash
# 1. Schema check (fastest; catches structural bugs)
x ajv -s .vscode/install.schema.json $(find src -name '*.yml')

# 2. install >= download invariant (catches stale estimates)
bash .x-cmd/install-download-check

# 3. yaml-lint (catches indentation / quoting bugs)
x bun x yaml-lint $(find src -name '*.yml')

# 4. (optional) Re-profile top-N popular entries on a weekly schedule
~/.x-repo/github.com/x-cmd-install/mneme/profile/scripts/measure.sh \
  --yml src/<category>/<tool>.yml
```

All four are read-only and combined finish in under a minute on the full
2,375-entry tree.

---

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

If you genuinely need to break a format's contract, ship a **new** format version (see [README → Format versioning](README.md#format-versioning-designed-for-forward-compatibility)). This is a larger contribution and warrants discussion in an issue first.

---

## Code of conduct

Standard open-source etiquette applies: be respectful, stay on topic, accept feedback gracefully. Maintainers reserve the right to close PRs that don't meet the quality bar or that don't engage with review.

---

## License

By submitting a contribution, you agree your contribution is licensed under **Apache 2.0**, matching the rest of the repository. See [LICENSE](LICENSE).