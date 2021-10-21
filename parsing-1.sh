

f(){
    awk -v target="$1" '
BEGIN {
    NAME = $0
}

$0!~/^#/{
    leading_space = match($0, /^[\ ]+/)
    leading_space_len = length(leading_space)

    if (leading_space_len == 0) {
        NAME = gsub(/[\ ]+$/, "", $0)
    } else if (leading_space_len == 4) {
        if ($1 == "reference") {

            return
        }

        if ($1 == "cmd") {

            return
        }
    }
}
' <index.yml

}

f kubectl

