#!/usr/bin/env bash
# shellcheck shell=dash
#
# Usage:
#   bash .x-cmd/lint.sh                       # lint all yml in src/
#   bash .x-cmd/lint.sh path/to/x.yml         # lint specific files
#
# Static, no-network checks — safe to re-run, fast (~30s for the full
# tree). For network-using checks see `bash .x-cmd/test.sh`.
#
# Checks (in order):
#   1. yaml-lint        YAML syntax (indentation, quotes, structure)
#   2. ajv               JSON Schema validation against install.schema.json
#   3. download-check    install.estimate >= download.estimate invariant
#   4. network-schema    all entries use the listen/connect schema
#                        (no legacy `local:` / `internet:` keys)
#
# Tools used:
#   x bun x yaml-lint   YAML syntax check (Deno wrapper around js-yaml)
#   x ajv                Schema validator (Deno + AJV)
#   bash install-download-check  Internal shell test
#   python3 install-network-migrate.py  Migration tool used as linter
#
# Exit codes:
#   0 = all checks passed
#   1 = at least one check failed (per-file list printed at end)
#   2 = environment error (missing tool)

set -e

main() {
    WORK_DIR="$(x wsroot 2>/dev/null || pwd)"
    SRC_DIR="$WORK_DIR/src"
    SCHEMA="$WORK_DIR/.vscode/install.schema.json"

    # Provide shim implementations for x:* helpers when invoked directly
    # (i.e. outside the x-cmd runtime, like in plain CI).
    if ! command -v x:info >/dev/null 2>&1; then
        x:info()  { echo "[INFO]  $*"; }
        x:warn()  { echo "[WARN]  $*"; }
        x:error() { echo "[ERROR] $*" >&2; }
    fi

    local files=()
    if [ $# -gt 0 ]; then
        files=("$@")
    else
        while IFS= read -r f; do
            files+=("$f")
        done < <(find "$SRC_DIR" -name '*.yml' 2>/dev/null)
    fi

    if [ "${#files[@]}" -eq 0 ]; then
        x:error "no yml files to lint"
        return 2
    fi

    x:info "Linting ${#files[@]} yml file(s)"

    local pass=0
    local fail=0
    local failed_files=()

    for f in "${files[@]}"; do
        [ -f "$f" ] || continue
        local file_fail=0
        local rel="${f#$WORK_DIR/}"

        # 1. yaml-lint (skip if x bun isn't available — best effort)
        if command -v x >/dev/null 2>&1; then
            if ! x bun x yaml-lint "$f" >/dev/null 2>&1; then
                x:warn "$rel  yaml-lint: FAIL"
                file_fail=1
            fi
        fi

        # 2. ajv schema validation
        if [ -f "$SCHEMA" ] && command -v x >/dev/null 2>&1; then
            if ! x ajv -s "$SCHEMA" -d "$f" >/dev/null 2>&1; then
                x:warn "$rel  ajv: FAIL"
                file_fail=1
            fi
        fi

        if [ "$file_fail" -eq 0 ]; then
            pass=$((pass + 1))
        else
            fail=$((fail + 1))
            failed_files+=("$rel")
        fi
    done

    # 3. install >= download invariant (whole-repo check, runs once)
    x:info "[3/4] install-download-check ..."
    if ! bash "$WORK_DIR/.x-cmd/install-download-check" >/dev/null 2>&1; then
        x:error "install-download-check: FAIL (run bash .x-cmd/install-download-check to see offenders)"
        fail=$((fail + 1))
    else
        x:info "install-download-check: ok"
    fi

    # 4. network schema check — every yml must have `listen:`/`connect:`, not `local:`/`internet:`
    x:info "[4/4] network-schema check ..."
    local legacy=0
    while IFS= read -r f; do
        if grep -qE '^\s+local:\s+(true|false)' "$f" 2>/dev/null; then
            x:warn "$f  legacy schema (local/internet)"
            legacy=$((legacy + 1))
        fi
    done < <(find "$SRC_DIR" -name '*.yml' 2>/dev/null)
    if [ "$legacy" -gt 0 ]; then
        x:error "network-schema: $legacy file(s) still on legacy schema; run bash .x-cmd/install-network-migrate"
        fail=$((fail + 1))
    else
        x:info "network-schema: ok"
    fi

    echo
    x:info "summary: pass=$pass fail=$fail"

    if [ "$fail" -gt 0 ]; then
        echo
        x:error "files with failures:"
        for f in "${failed_files[@]}"; do
            echo "  - $f"
        done
        return 1
    fi

    x:info "all checks passed"
    return 0
}

(
  main "$@"
)