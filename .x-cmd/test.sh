# shellcheck shell=dash
#
# Usage:
#   x ws test                  # full suite (default)
#   x ws test sample            # re-measure 3 random # already profiled entries
#
# Full suite. Runs test.smoke.sh first, then re-measures a sample of
# profiled entries to verify values haven't drifted.

WS="$(x wsroot)"
SRC="$WS/src"
HARNESS="$HOME/.x-repo/github.com/x-cmd-install/mneme/profile/scripts/measure.sh"

sample(){
    grep -lr '^# already profiled' "$SRC" 2>/dev/null \
        | shuf -n 3 \
        | while IFS= read -r f; do
            timeout 90 "$HARNESS" --yml "$f" > /tmp/sample.out 2>&1 \
                && x:info "  ✓ ${f#$WS/}" \
                || { x:error "  ✗ ${f#$WS/}"; cat /tmp/sample.out; exit 1; }
        done
}

main(){
    case "${1:-all}" in
        sample) sample ;;
        all|default|"") x ws test.smoke && sample ;;
        *) x:error "unknown: $1"; return 2 ;;
    esac
}

(
    main "$@"
)