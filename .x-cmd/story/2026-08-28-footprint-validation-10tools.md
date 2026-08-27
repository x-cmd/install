# footprint Schema Validation — 10 Tools

**Date**: 2026-08-28
**Branch**: `durdraw-install-methods`
**Pilot**: `easy-rsa.yml`
**Validation set**: 10 tools spanning diverse runtime types

## Validation Set

| Tool | Runtime | Network | Disk r | Mem [i,p] | CPU [i,p] |
|---|---|---|---|---|---|
| `htop` | `tui` | L✓ / I✗ | 1 (1 MB) | [2, 2] | [1, 2] |
| `bpytop` | `tui` | L✓ / I✗ | 1 (5 MB) | [3, 4] | [1, 2] |
| `bottom` | `tui` | L✓ / I✗ | 1 (5 MB) | [2, 3] | [1, 2] |
| `fastfetch` | `cli` | L✓ / I✗ | 1 (2 MB) | [2, 2] | [0, 3] |
| `procs` | `cli` | L✓ / I✗ | 1 (5 MB) | [2, 2] | [0, 2] |
| `pass-cli` | `[cli, tui]` | L✓ / I✓ | 2 (10 MB) | [2, 3] | [0, 4] |
| `git-irt` | `tui` | L✓ / I✗ | 1 (5 MB) | [2, 3] | [1, 2] |
| `nginx` | `daemon` | L✓ / I✓ | 2 (10 MB) | [2, 4] | [0, 6] |
| `emacs` | `[cli, tui, gui]` | L✓ / I✓ | 3 (50 MB) | [3, 4] | [0, 4] |
| `certbot` | `[cli, oneshot]` | L✓ / I✓ | 1 (5 MB) | [2, 3] | [0, 3] |

(L=local, I=internet; r=rating; i/p=idle/peak)

## Schema Issues Found

### 🔴 Critical

1. **YAML `yes/no` boolean quirk**
   - `local: yes` parses as `True` in YAML 1.1 (PyYAML default)
   - **Fix**: use explicit `true` / `false` in yml, OR change schema to `"yes"` / `"no"` strings
   - Currently renders as `LTrue/IFalse` in tools — ugly

2. **Empty lists are noise**
   - `disk.paths.data: []` and `cache: []` are empty for 6+ tools
   - **Fix**: make `cache` optional (omit when empty); `data` may be required but allow `[]`

3. **`disk.size.growth` often trivial**
   - 7/10 tools have "几乎不增长" (no persistent growth)
   - **Fix**: make `growth` optional, omit when "no growth"

### 🟡 Semantic ambiguity

4. **`network.local` semantics unclear**
   - Current: "reads local filesystem/proc/sockets"
   - Could be: "listens on localhost only" or "reads /proc"
   - **Decision needed**: doc the meaning. Currently I used it as "any local IPC".

5. **Daemon baseline/peak semantics differ from CLI**
   - CLI: baseline = idle, peak = single-shot operation spike
   - Daemon: baseline = steady-state load, peak = under-traffic load
   - **Schema**: same `{rating, desc}` shape works but **descriptions need different vocabulary**
   - For nginx: `idle.rating: 0` (no traffic) → `peak.rating: 6` (under load)

6. **Multi-process `cpu.processes` rating semantics**
   - `nginx` has master + 3 workers (4 processes)
   - Rating applies **per process** but memory total is multiplied
   - **Schema**: should clarify "rating is per-process" or add `cpu.processes.total_mem` separately

7. **`runtime.type` for daemon + CLI binaries**
   - `nginx` is daemon but `nginx -s reload` is CLI invocation
   - Currently classified as `daemon` only
   - **Option**: support `[daemon, cli]` list (like claude-code)

8. **`cpu.workload: [io, compute]` order semantics**
   - Does order matter? `[io, compute]` vs `[compute, io]` — same set or different meaning?
   - **Fix**: doc that order is not semantic; treat as set

### 🟢 Schema noise

9. **Repetition of "几乎不增长" across 7 files**
   - Boilerplate; would benefit from a shorthand like `growth: none`

10. **`mem.idle.rating: 2` for many tools (~30 MB)**
    - Real rating should distinguish (Python interpreter = heavier than native CLI)
    - Current rubric is too coarse around the 30-100 MB band

11. **All 10 tools have `disk.paths.config` listed**
    - Some don't actually have user-configurable config files (htop, fastfetch have defaults baked in)
    - **Schema**: allow `config: []` but encourage omission when no config

## Schema Quirks (technical)

12. **Nested bilingual `desc` doubles field count**
    - Every `desc: { cn, en }` is 2 strings
    - Some contributors may only fill `en`, breaking required-ness
    - **Decision**: make `cn` optional (since x-cmd is bilingual but English is base)

13. **`memory.idle` and `memory.peak` may collapse for some tools**
    - CLI tools: `idle ≈ peak` (steady ~30 MB)
    - **Schema**: allow omission of `peak` if same as `idle`

14. **Field placement of `cpu.workload`**
    - It's a classification, not a measurement
    - Currently mixed with `processes` (also metadata) and `idle/peak` (measurements)
    - **Fix**: group as `cpu.meta: { workload, processes }` vs `cpu.measure: { idle, peak }`

## Schema Strengths

✅ **`runtime.type` list support** — handled `pass-cli` `[cli, tui]`, `emacs` `[cli, tui, gui]`, `certbot` `[cli, oneshot]` cleanly
✅ **`sensitive` path lists** — explicit, queryable; caught `fastfetch`'s `dmidecode` system serial leak
✅ **`disk.paths.{data,config,cache}`** — actionable for backup/uninstall AI
✅ **0-9 rating** — quick cross-tool comparison; `nginx` peak CPU 6 vs `htop` peak 2 immediately reveals resource class
✅ **`cpu.workload` list** — `htop` `[io]` vs `fastfetch` `[io, compute]` shows distinction
✅ **`growth` field** — flagged nginx's log growth concern, easy-rsa's PKI growth

## Recommended Schema Tweaks (next iteration)

### Make optional
- `disk.size.growth` — only fill when actually grows
- `disk.paths.cache` — omit when empty
- `memory.peak` — omit when equal to idle (CLI tools)
- `cpu.workload` — default `[compute]`? Or require explicit
- `cpu.processes` — default `1`

### Fix
- Use explicit `true`/`false` (not `yes`/`no`)
- Document `network.local` semantics ("reads local IPC or filesystem")
- Document `cpu.processes` rating semantics ("per process")

### Add
- `T1` / `T2` / `T3` tier markers in CONTRIBUTING.md:
  - **T1 (required)**: `runtime.type`, `network.{local,internet}`, `disk.size.install.{estimate,rating}`, `disk.paths.{data,config}` (or empty)
  - **T2 (recommended)**: `filesystem.read.sensitive`, `cpu.workload`, `cpu.processes`, `memory.{idle,peak}`
  - **T3 (full disclosure)**: `cpu.idle/peak`, `disk.size.growth`, `disk.paths.cache`, `filesystem.write.sensitive`

## Validation Verdict

**Schema works for 10 diverse tools** — covers CLI, TUI, GUI, daemon, oneshot, library-shapes, sensitive paths, network access, multi-process. No tool was unrepresentable.

**3 critical fixes needed** before public rollout:
1. `yes/no` → `true/false` (or string)
2. Make `cache`/`growth`/`peak` optional
3. Document semantic ambiguities (`local`, `cpu.processes`, daemon vs CLI baseline/peak)

**Schema is production-ready** with these tweaks for v1 publication.

## Files Touched

- `src/osman/easy-rsa.yml` (pilot, already committed)
- `src/osman/htop.yml`
- `src/osman/bpytop.yml`
- `src/osman/bottom.yml`
- `src/osman/fastfetch.yml`
- `src/osman/procs.yml`
- `src/osman/pass-cli.yml` (also fixed `network.local` bug)
- `src/osman/git-interactive-rebase-tool.yml`
- `src/web-infrastructure/nginx.yml`
- `src/editor/emacs.yml`
- `src/network/certbot.yml`