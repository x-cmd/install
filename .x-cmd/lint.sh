# shellcheck shell=dash
#
# Usage:
#   x ws lint <file>...      Lint the specified YAML files
#
# Examples:
#   x ws lint src/ai/claude-code.yml
#   x ws lint src/ai/*.yml
#
# File-level linter — yaml + ajv per file, parallel via x line args.
# Subset of smoke.test.sh ⊂ test.sh.

mainrun(){
    for f in "$@"; do
        x bun x yaml-lint "$f" || x:error "yaml-lint failed -> $f"
        x bun x ajv-cli -s "$(x wsroot)/.vscode/install.schema.json" -d "$f" || x:error "ajv-cli failed -> $f"
    done
}

(
    if [ $# -eq 0 ]; then
        find "$(x wsroot)/src" -name "*.yml" | x line args -n 1000 'mainrun "$@"'
    else
        mainrun "$@"
    fi
)