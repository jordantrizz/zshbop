# =============================================================================
# -- Coding Commands
# =============================================================================
_debug " -- Loading ${(%):-%N}"
help_files[coding]='Coding related commands'
typeset -gA help_coding

# ==================================================
# -- count-lines
# ==================================================
help_coding[count-lines]='Count lines in files with specific extension'
function count-lines() {
    local ext=$1
    if [[ -z "$ext" ]]; then
        echo "Usage: count-lines <extension>"
        echo "Example: count-lines php"
        return 1
    fi

    # Remove dot if present
    ext=${ext#.}

    echo "${ext:u} Files Line Count Report"
    echo "============================"
    echo ""

    local total_lines=0
    local file_count=0

    # Find all files with extension, store with line counts, then sort by line count descending
    # Exclude vendor and node_modules directories
    while IFS= read -r line; do
        local lines=$(echo "$line" | awk '{print $1}')
        local file=$(echo "$line" | awk '{$1=""; print substr($0,2)}')
        
        # Skip if lines is not a number (sanity check)
        if [[ ! "$lines" =~ ^[0-9]+$ ]]; then
            continue
        fi

        total_lines=$((total_lines + lines))
        file_count=$((file_count + 1))
        printf "%-60s %6d lines\n" "$file" "$lines"
    done < <(find . -name "*.$ext" -not -path "*/vendor/*" -not -path "*/node_modules/*" -exec wc -l {} + 2>/dev/null | grep -v "total$" | sort -rn)

    echo ""
    echo "============================"
    echo "Total: $file_count files, $total_lines lines"
}
