# shellcheck shell=dash
#
# Usage:
#   x ws test.smoke
#
# Fast integration (~30s). Runs lint.sh first, then rate-limit, harness
# smoke, and heavier invariants. Subset of test.sh.

x ws lint
gh api rate_limit --jq '.rate.remaining' 2>/dev/null | awk '{ exit ($1+0 < 30) }'
bash "$(x wsroot)/.x-cmd/install-download-check"
x wsroot >/dev/null
