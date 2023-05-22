# -- file
_debug " -- Loading ${(%):-%N}"
help_files[cron]="Commands working with files in Linux" # Help file description
typeset -gA help_file # Init help array.

function compare-dirs () {
    local DIR1=$1
    local DIR2=$2

    if [[ ! -d "$DIR1" || ! -d "$DIR2" ]]; then
    echo "Usage: compare-dirs <dir1> <dir2>"
    return 1
    fi

    diff -rq "$DIR1" "$DIR2"
}



