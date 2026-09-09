# shellcheck shell=dash
#
# Usage:
#   x ws lint                    # lint all yml in src/
#   x ws lint path/to/x.yml      # lint specific files
#
# File-level linter. Subset of smoke.test.sh ⊂ test.sh.

WS="$(x wsroot)"
A="$WS/.x-cmd/install-yml-check.schema.json"
B="$WS/.vscode/install.schema.json"

# Bail early if the two schema copies have drifted.
diff -q "$A" "$B" >/dev/null 2>&1 || {
    x:error "schema drift: $A vs $B differ; run: cp $A $B (or vice versa)"
    exit 1
}

x ajv -s "$A" "$@"