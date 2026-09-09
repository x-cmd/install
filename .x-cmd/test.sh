#!/usr/bin/env bash
# shellcheck shell=dash
#
# Usage:
#   bash .x-cmd/test.sh                    # run all network-using checks
#   bash .x-cmd/test.sh schema             # only schema validation
#   bash .x-cmd/test.sh sample             # measure a sample of entries
#   bash .x-cmd/test.sh harness            # verify measure.sh works end-to-end
#
# Network-using checks (slower than lint.sh — minutes not seconds).
# Each check is idempotent and runs in isolation so failures don't block
# the rest.
#
# Checks:
#   schema     run x ajv against every yml in src/ (fast, ~30s)
#   sample     measure 5 random `# already profiled` entries via measure.sh
#              to verify the harness still works end-to-end
#   harness    verify measure.sh itself works (eget + container + sampling)
#   rate-limit  verify GitHub API rate limit is healthy enough for profiling
#   (default)   schema + rate-limit (safe default; no random sampling)
#
# Tools used:
#   x ajv                 Deno + AJV schema validator
#   bash lint.sh          delegates static checks here
#   ~/.x-repo/github.com/x-cmd-install/mneme/profile/scripts/measure.sh
#                          container-based measurement harness
#   gh api                 GitHub API for rate-limit probe
#
# Exit codes:
#   0 = all requested checks passed
#   1 = at least one check failed
#   2 = environment error (missing tools)

set -e

main() {
    WORK_DIR="$(x wsroot 2>/dev/null || pwd)"
    SRC_DIR="$WORK_DIR/src"
    HARNESS="$HOME/.x-repo/github.com/x-cmd-install/mneme/profile/scripts/measure.sh"

    if ! command -v x:info >/dev/null 2>&1; then
        x:info()  { echo "[INFO]  $*"; }
        x:warn()  { echo "[WARN]  $*"; }
        x:error() { echo "[ERROR] $*" >&2; }
    fi

    local mode="${1:-default}"
    local fail=0

    case "$mode" in
        default)
            run_schema || fail=1
            run_rate_limit || fail=1
            ;;
        schema)
            run_schema || fail=1
            ;;
        sample)
            run_schema || fail=1
            run_rate_limit || fail=1
            run_sample || fail=1
            ;;
        harness)
            run_harness_smoke || fail=1
            ;;
        rate-limit)
            run_rate_limit || fail=1
            ;;
        all)
            run_schema    || fail=1
            run_rate_limit || fail=1
            run_harness_smoke || fail=1
            run_sample    || fail=1
            ;;
        *)
            x:error "unknown mode: $mode (use default|schema|sample|harness|rate-limit|all)"
            return 2
            ;;
    esac

    if [ "$fail" -eq 0 ]; then
        x:info "test passed"
        return 0
    fi
    x:error "test failed"
    return 1
}

run_schema() {
    x:info "[schema] running x ajv against all yml ..."
    if ! command -v x >/dev/null 2>&1; then
        x:error "x command not found"
        return 1
    fi
    if ! find "$SRC_DIR" -name '*.yml' | x ajv -s "$WORK_DIR/.vscode/install.schema.json" 2>&1 >/dev/null; then
        x:error "schema: FAIL — run 'bash .x-cmd/lint.sh' for details"
        return 1
    fi
    x:info "schema: ok"
}

run_rate_limit() {
    x:info "[rate-limit] probing GitHub API ..."
    if ! command -v gh >/dev/null 2>&1; then
        x:warn "gh not installed; skipping rate-limit probe"
        return 0
    fi
    local rl
    rl=$(gh api rate_limit --jq '.rate.remaining,.rate.reset' 2>/dev/null || echo "")
    if [ -z "$rl" ]; then
        x:warn "could not query rate limit; assuming OK"
        return 0
    fi
    local remaining
    remaining=$(echo "$rl" | head -1)
    local reset
    reset=$(echo "$rl" | tail -1)
    if [ "${remaining:-0}" -lt 30 ]; then
        local now
        now=$(date '+%s')
        local wait_sec=$(( reset - now ))
        x:warn "rate limit low: remaining=$remaining, resets in $((wait_sec/60)) min"
        x:warn "  profiling will fail until reset; either wait or use a GH token"
        return 1
    fi
    x:info "rate-limit: $remaining remaining"
}

run_harness_smoke() {
    x:info "[harness] smoke-testing measure.sh on jq ..."
    if [ ! -x "$HARNESS" ]; then
        x:error "harness not found at $HARNESS"
        return 1
    fi
    local tmpdir
    tmpdir=$(mktemp -d -t footprint-smoke.XXXXXX)
    trap 'rm -rf "$tmpdir"' EXIT
    # We use the yml path so the harness reads the same yml we'd use in CI
    if ! timeout 90 "$HARNESS" --yml "$SRC_DIR/data-json-yml/jq.yml" > "$tmpdir/out.txt" 2>&1; then
        x:error "harness: FAIL — see $tmpdir/out.txt"
        cat "$tmpdir/out.txt"
        return 1
    fi
    if ! grep -q '^disk_human=' "$tmpdir/out.txt"; then
        x:error "harness: no disk_human output (broken?)"
        cat "$tmpdir/out.txt"
        return 1
    fi
    local size
    size=$(grep '^disk_human=' "$tmpdir/out.txt" | head -1 | cut -d= -f2)
    x:info "harness: ok (jq disk_human=$size)"
}

run_sample() {
    x:info "[sample] measuring 3 random # already profiled entries ..."
    if [ ! -x "$HARNESS" ]; then
        x:error "harness not found at $HARNESS"
        return 1
    fi
    local sample=()
    while IFS= read -r f; do
        sample+=("$f")
    done < <(grep -lr '^# already profiled' "$SRC_DIR" 2>/dev/null | shuf -n 3 2>/dev/null \
             || grep -lr '^# already profiled' "$SRC_DIR" 2>/dev/null | head -3)
    if [ "${#sample[@]}" -lt 3 ]; then
        x:warn "fewer than 3 profiled entries available; skipping sample"
        return 0
    fi
    local fail=0
    for yml in "${sample[@]}"; do
        local rel="${yml#$WORK_DIR/}"
        if timeout 90 "$HARNESS" --yml "$yml" > /tmp/sample-test-out.txt 2>&1; then
            x:info "  ✓ $rel"
        else
            x:error "  ✗ $rel"
            fail=1
        fi
    done
    [ "$fail" -eq 0 ]
}

(
  main "$@"
)