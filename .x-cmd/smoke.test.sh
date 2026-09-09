# shellcheck shell=dash
#
# Usage:
#   x ws smoke.test                  # all smoke checks
#   x ws smoke.test <check>          # one check (lint|rate-limit|harness|invariants)
#
# Smoke integration (~30s). Runs lint.sh first, then rate-limit probe,
# harness smoke test, and the heavier invariants. Subset of test.sh.

WS="$(x wsroot)"
SRC="$WS/src"
SCHEMA="$WS/.vscode/install.schema.json"
HARNESS="$HOME/.x-repo/github.com/x-cmd-install/mneme/profile/scripts/measure.sh"

lint(){
    x ws lint
}

rate_limit(){
    gh api rate_limit --jq '.rate.remaining' 2>/dev/null \
        | awk '{ if ($1+0 < 30) { exit 1 } }' \
        || x:warn "rate limit low ($1 remaining)"
}

harness(){
    timeout 90 "$HARNESS" --yml "$SRC/data-json-yml/jq.yml" > /tmp/harness.out 2>&1 \
        && grep -q '^disk_human=' /tmp/harness.out \
        || { x:error "harness smoke failed"; cat /tmp/harness.out; exit 1; }
}

invariants(){
    bash "$WS/.x-cmd/install-download-check" || { x:error "download-check failed"; exit 1; }
    grep -lE '^\s+local:\s+(true|false)' "$SRC"/*/*.yml 2>/dev/null \
        | { ! grep . ; } || { x:error "legacy network schema"; exit 1; }
}

main(){
    case "${1:-all}" in
        lint)        lint ;;
        rate-limit)  rate_limit ;;
        harness)     harness ;;
        invariants)  invariants ;;
        all|default|"")
            lint && rate_limit && harness && invariants
            ;;
        *) x:error "unknown: $1"; return 2 ;;
    esac
}

(
    main "$@"
)