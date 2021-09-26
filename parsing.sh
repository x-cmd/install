

f(){
    awk -v target="$1" '
$0!~/^#/{
    if ($0~/^[\ ]+/) {
        CODE = CODE "\n" $0
    } else {
        if (NAME == target) {
            CODE = substr(CODE, 2)
            print CODE
            exit(0)
        }

        NAME = substr($0, 1, length($0)-1)
        CODE = ""
    }
}
' <index.yml

}

f kubectl

