# footprint Schema Design Story

**Date**: 2026-08-28
**Branch**: `durdraw-install-methods`
**Pilot file**: `src/osman/easy-rsa.yml`
**Commits**: `3b699f6`, `1430104`, `80c8c0a`

## Context

We started from a failing `x eget` install for `durdraw` (Python tool, no binary releases) and pivoted to designing a new metadata layer — `footprint` — to disclose resource + permission + behavior information about each tool. `easy-rsa` was chosen as the pilot because it has a meaningful disk/CPU/memory/permission profile that exercises every dimension.

The goals driving this work:
1. **Horizontal comparison** across tools in the registry (resource, permission, behavior dimensions)
2. **Operational scripts** — AI agents generating `uninstall` / `backup` commands from the yml
3. **Future monetization** — a "footprint rating" standard that distinguishes tools by system impact

## Design Journey (key iterations)

### Round 1: Information architecture

We explored dozens of names for the top-level key:
- `info` (rejected — too generic)
- `profile` (rejected by user — "sounds like intro")
- `surface` (rejected — security-flavored)
- `manifest` (rejected — sounds like a list)
- `descriptor` (rejected — too formal)
- `footprint` ← **chosen** (analytical + commercial weight, "carbon footprint" / "security footprint" precedent)
- `model` (rejected — too ambiguous)
- `characterization` (rejected — too long)

### Round 2: `runtime.type` taxonomy

We landed on the enum:
```
cli | tui | gui | daemon | oneshot | interactive | library
```
with **list support** for hybrid tools (`type: [cli, interactive]` for claude-code; `type: [cli, tui]` for vim; `type: [gui, cli]` for VS Code).

We also clarified that `lang` (Python/Rust/Go) is **orthogonal** to `runtime.type` — Python can be any type.

### Round 3: CPU quantification debate

CPU was the hardest dimension because:
- **Percentage (%)** doesn't work cross-machine
- **Anchor benchmarks** (`≈ openssl genrsa 4096`) are not queryable
- **cores × duration** is still machine-dependent in practice

Final decision: **0-9 standardized rating** with `x-cmd`-defined rubric (see Rubric section below).

### Round 4: `mem` / `cpu` symmetry

We unified both into `idle` / `peak` scenarios (renamed from `baseline`/`peak`) for parallel semantics. Dropped `mem.avg` (redundant — bimodal distributions make average meaningless).

### Round 5: `permission` split

`permission` was a grab-bag containing `runtime`, `network`, `read`, `write`. Split into:
- `behavior.runtime` — operational mode
- `behavior.network` — network access
- `behavior.filesystem.read` / `.write` — file access

### Round 6: `disk` split

`disk` mixed two concepts (size + paths). Split into:
- `disk.size.install` / `.growth`
- `disk.paths.data` / `.config` / `.cache`

### Round 7: `footprint.score` dropped

I proposed a single composite score, but we agreed it has no defensible formula and is computable from existing ratings. **Dropped.**

## Final Schema

```yaml
footprint:
  # ─── behavior: what the tool does ───
  behavior:
    runtime:
      type: cli | tui | gui | daemon | oneshot | interactive | library
            # also supports list: type: [cli, tui]

    network:
      local: yes/no
      internet: yes/no
      desc: { cn, en }    # optional, omitted when both are no

    filesystem:
      read:
        desc: { cn, en }
        sensitive: [path patterns]   # only the sensitive subset
      write:
        desc: { cn, en }
        sensitive: [path patterns]

  # ─── resource: how much it consumes ───
  resource:
    disk:
      size:
        install:
          estimate: "5 MB"        # absolute, for backup planning
          rating: 1               # 0-9, for cross-tool comparison
          desc: { cn, en }
        growth:
          desc: { cn, en }        # qualitative, no number
      paths:                       # canonical filesystem locations
        data: [path patterns]
        config: [path patterns]
        cache: [path patterns]

    memory:
      idle:
        rating: 0-9
        desc: { cn, en }
      peak:
        rating: 0-9
        desc: { cn, en }

    cpu:
      workload: [compute | io | ...]   # list, not map
      processes: int                   # process count
      idle:
        rating: 0-9
        desc: { cn, en }
      peak:
        rating: 0-9
        desc: { cn, en }
```

## Rating Rubric (x-cmd standard)

| Rating | CPU reference (mid-range x86) | Memory reference |
|---|---|---|
| 0 | idle process | 0 MB |
| 1 | `echo`, `true` | <5 MB |
| 2 | `ls`, `cat` small file | 5-50 MB (typical CLI) |
| 3 | `git status`, `grep` small file | 50-100 MB |
| 4 | `find`, `grep` large tree | 100-300 MB |
| 5 | `git clone` small repo, `tar` small archive | 300 MB - 1 GB |
| 6 | `git clone` large repo, small `make -j` | 1-2 GB |
| 7 | `openssl genrsa 4096`, `ffmpeg` short clip | 2-4 GB |
| 8 | `ffmpeg` HD transcode, Linux `make -j` | 4-8 GB |
| 9 | 4K transcode, full disk backup, RSA 16384 | 8+ GB |

## Decisions Log

| Decision | Rationale |
|---|---|
| `footprint` over `info` / `profile` | Analytical + commercial weight; "manage your footprint" is a SaaS-ready phrase |
| 0-9 rating (not %) | Machine-independent; comparable across tools; community-building standard opportunity |
| `behavior` / `resource` split | Two different semantic dimensions (what vs. how much) |
| `disk.size` separate from `disk.paths` | Two concepts previously conflated |
| `sensitive` as path list (not bool) | Cross-tool grep: "show me tools reading `*.key`" |
| Drop `footprint.score` | Derived field, computable from ratings, no extra info |
| `lang` orthogonal to `runtime.type` | Python/Rust is implementation; cli/daemon is operation |
| List for hybrid runtime types | Captures `vim` (cli+tui), VS Code (gui+cli) |
| Drop `network.desc` when both bools are no | Redundant; bool pair already encodes "offline" |
| Drop `mem.avg` | Bimodal distributions make average meaningless |

## Easy-rsa.yml Pilot Values

| Field | Value |
|---|---|
| `behavior.runtime.type` | `cli` |
| `behavior.network.local/internet` | `no / no` |
| `behavior.filesystem.read.sensitive` | `$EASYRSA_PKI/private/*.key`, `$EASYRSA_PKI/reqs/*.req`, `$EASYRSA_PKI/pki/passwords.txt` |
| `resource.disk.size.install.estimate` | `5 MB` |
| `resource.disk.size.install.rating` | `1` |
| `resource.disk.paths.data` | `$EASYRSA_PKI` |
| `resource.disk.paths.config` | `$EASYRSA/vars`, `$EASYRSA/openssl-easyrsa.cnf` |
| `resource.memory.idle.rating` | `2` (~30 MB) |
| `resource.memory.peak.rating` | `3` (~60 MB) |
| `resource.cpu.workload` | `[compute]` |
| `resource.cpu.processes` | `1` |
| `resource.cpu.idle.rating` | `0` |
| `resource.cpu.peak.rating` | `7` (RSA-4096 class) |

## Open Questions / Next Steps

1. **Schema validation** — `install-yml-check.schema.json` still doesn't declare `footprint` fields; lint will fail until updated
2. **Rubric publication** — `CONTRIBUTING.md` should host the rating rubric as the official reference
3. **Cross-tool queries** — design queries that consume this schema (e.g., `x footprint list --max-rating 3`)
4. **AI uninstall/backup generation** — prototype AI agent that reads `behavior.*` + `resource.disk.paths.*` to emit shell scripts
5. **Pilot expansion** — apply this schema to `durdraw` (CLI tool), `nginx` (daemon), `vscode` (gui), `claude-code` (`[cli, interactive]` hybrid) to validate
6. **T1/T2/T3 tiering** — formalize minimum/recommended/full disclosure tiers (we discussed this earlier, never wrote it down)
7. **Display layer** — how to render `rating: 7` in user-facing advise ("high CPU peak") — needs design

## Out of Scope (deferred)

- **Live measurement** — rating is declared, not measured; runtime profiling could come later
- **Auto-derivation** — `filesystem.paths` from install rules, `runtime.type` from `binlist` heuristics
- **Compliance/security scoring** — derived from `sensitive` lists + `network.internet` booleans

---

**Status**: Pilot complete on `easy-rsa.yml`. Ready to expand to other categories.