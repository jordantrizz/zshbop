# -- file
_debug " -- Loading ${(%):-%N}"
help_files[file]="Commands working with files in Linux" # Help file description
typeset -gA help_file # Init help array.

# -- Compare two directories
help_file[compare-dirs]="Compare two directories"
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
help_file[zipc]="Zip a directory"
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
help_file[gzip-files]="Gzip all files in a directory"
gzip-files() {
    if [[ $1 == "-h" || $1 == "--help" || -z $1 ]]; then
        echo "Usage: gzip-files <dir>"
        return 1
    fi

    for file in "$@"; do
        gzip "$file"
    done
}

# -- findk
help_file[findk]="Find a file with wildcard keywords, hardlinked and inode"
findk () {
    local QUERY="" FOUND_FILES="" FOUND_FILES_COUNT=0 FOUND_FILES_TITLE="" FOUND_FILES_OUTPUT=""
    # Get current directory
    local CURRENT_DIR=$(pwd)

    # Check if we have any arguments
    for word in "$@"; do
        QUERY+="*$word"
    done

    # Execute the find command
    _loading "Finding - find $CURRENT_DIR -iname $QUERY*"
    
    echo ""
    
    FOUND_FILES+=$(find . -iname "$QUERY*" -printf "%i %n %s %y %p\n" | awk '{if ($4 == "f") { printf "%s\t%s\t%.2fMB \t%s\t", $1, $2, $3/1024/1024, $4; for (i=5; i<=NF; i++) printf "%s ", $i; print ""} else { printf "%s\t%s\t - \t%s\t", $1, $2, $4; for (i=5; i<=NF; i++) printf "%s ", $i; print ""}}')
    FOUND_FILES_COUNT=$(echo "$FOUND_FILES" | wc -l)
    FOUND_FILES_TITLE="Inode\tLinks\tSize\tType\tPath\n"
    FOUND_FILES_TITLE+="=====\t=====\t====\t====\t===========\n"
    
    FOUND_FILES_OUTPUT=$FOUND_FILES_TITLE"\n"$FOUND_FILES
    echo "$FOUND_FILES_OUTPUT" | column -t -s $'\t'
    echo ""
    echo "Found files: $FOUND_FILES_COUNT"

}

# -- find-empty-dirs
help_file[find-empty-dirs]="Find empty directories"
function find-empty-dirs () {
    find . -type d -empty
}

# -- super-chown
help_file[super-chown]="Change ownership of files and directories"
function super-chown () {
    _loading "Here are some good examples"

    echo="
    fixHomeOwnership() {
        for dir in /home/*; do
            if [[ -d $dir ]]; then
                # Extract the username from the directory path
                user=$(basename "$dir")

                # Change the ownership of the directory
                echo "Changing ownership of $dir to $user"
                chown -R $user:$user "$dir"
            fi
        done
    }
    "

    echo="
    fixHomeOwnershipBasedOnCurrent() {
        for dir in /home/*; do
            if [[ -d $dir ]]; then
                # Get the current owner of the directory
                owner=$(ls -ld "$dir" | awk '{print $3}')

                # Get the group of the directory
                group=$(ls -ld "$dir" | awk '{print $4}')

                # Apply the ownership recursively
                echo "Setting ownership of $dir to $owner:$group"
                chown -R $owner:$group "$dir"
            fi
        done
    }
    "

}