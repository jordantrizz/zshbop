# -- file
_debug " -- Loading ${(%):-%N}"
help_files[file]="Commands working with files in Linux" # Help file description
typeset -gA help_file # Init help array.

# -- Compare two directories
help_files[compare-dirs]="Compare two directories"
function compare-dirs () {
    local DIR1=$1
    local DIR2=$2

    if [[ ! -d "$DIR1" || ! -d "$DIR2" ]]; then
    echo "Usage: compare-dirs <dir1> <dir2>"
    return 1
    fi

    diff -rq "$DIR1" "$DIR2"
}

# -- zipc
help_files[zipc]="Zip a directory"
function zipc () {
    local DIR=$1
    local ZIPNAME=$2

    if [[ ! -d "$DIR" ]]; then
    echo "Usage: zipc <dir> <zipname>"
    return 1
    fi

    if [[ ! -n "$ZIPNAME" ]]; then
    echo "Usage: zipc <dir> <zipname>"
    return 1
    fi

    zip -r "$ZIPNAME" "$DIR"
}

# -- gzip-files
help_files[gzip-files]="Gzip all files in a directory"
gzip-files() {
    if [[ $1 == "-h" || $1 == "--help" || -z $1 ]]; then
        echo "Usage: gzip-files <dir>"
        return 1
    fi

    for file in "$@"; do
        gzip "$file"
    done
}