# =============================================================================
# -- Coding Commands
# =============================================================================
_debug " -- Loading ${(%):-%N}"
help_files[coding]='Coding related commands'
typeset -gA help_coding

# =============================================================================
# -- count-lines
# ===============================================
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

# ===============================================
# -- zshbop-code-audit
# ===============================================
help_coding[code-audit]='Audit comment divider (=) lengths in script headers and function/section headers'
help_zshbop[code-audit]='Audit comment divider (=) lengths in script headers and function/section headers'

function zshbop-code-audit () { zshbop_code-audit "$@" }

function zshbop_code-audit () {
    typeset -a OPTS_HELP OPTS_JSON
    typeset -a OPTS_HEADER_LINES OPTS_TOP OPTS_ROOT
    typeset -a OPTS_FIX OPTS_DRY_RUN
    typeset -a OPTS_SECTION_WIDTH OPTS_MAJOR_WIDTH OPTS_MAJOR_TOP_LINES

    typeset HEADER_LINES=20
    typeset TOP_N=8
    typeset ROOT_DIR="${ZSHBOP_ROOT:-$PWD}"

    typeset SECTION_WIDTH=47
    typeset MAJOR_WIDTH=77
    typeset MAJOR_TOP_LINES=8

    zparseopts -D -E -- \
        h=OPTS_HELP -help=OPTS_HELP \
        j=OPTS_JSON -json=OPTS_JSON \
        f=OPTS_FIX -fix=OPTS_FIX \
        d=OPTS_DRY_RUN -dry-run=OPTS_DRY_RUN \
        n:=OPTS_HEADER_LINES -header-lines:=OPTS_HEADER_LINES \
        t:=OPTS_TOP -top:=OPTS_TOP \
        r:=OPTS_ROOT -root:=OPTS_ROOT \
        s:=OPTS_SECTION_WIDTH -section-width:=OPTS_SECTION_WIDTH \
        m:=OPTS_MAJOR_WIDTH -major-width:=OPTS_MAJOR_WIDTH \
        M:=OPTS_MAJOR_TOP_LINES -major-top-lines:=OPTS_MAJOR_TOP_LINES

    if [[ -n $OPTS_HELP ]]; then
        echo "Usage: zshbop code-audit [-n <header_lines>] [-t <top_n>] [-r <root_dir>] [-j] [-f] [-d] [-s <section_width>] [-m <major_width>] [-M <major_top_lines>]"
        echo "  -n <header_lines>   How many lines from top-of-file count as 'script header' (default: ${HEADER_LINES})"
        echo "  -t <top_n>          Show top N divider widths per bucket (default: ${TOP_N})"
        echo "  -r <root_dir>       Root directory to scan (default: \$ZSHBOP_ROOT or cwd)"
        echo "  -j                  Output JSON instead of human text"
        echo "  -f, --fix           Normalize '=' divider widths in-place"
        echo "  -d, --dry-run       With --fix, report changes but do not write files"
        echo "  -s <width>          Section divider width (default: ${SECTION_WIDTH})"
        echo "  -m <width>          Major divider width (default: ${MAJOR_WIDTH})"
        echo "  -M <lines>          Treat divider lines in first N lines as 'major' (default: ${MAJOR_TOP_LINES})"
        echo ""
        echo "Scans *.zsh files for comment divider lines like: '# ========' and counts the number of '=' characters."
        echo ""
        echo "Suggested standard for this repo (based on current usage):"
        echo "  - Section/function dividers: ${SECTION_WIDTH} '='"
        echo "  - Major/top-of-file dividers: ${MAJOR_WIDTH} '='"
        return 0
    fi

    if [[ -n $OPTS_HEADER_LINES ]]; then
        HEADER_LINES="${OPTS_HEADER_LINES[2]}"
    fi
    if [[ -n $OPTS_TOP ]]; then
        TOP_N="${OPTS_TOP[2]}"
    fi
    if [[ -n $OPTS_ROOT ]]; then
        ROOT_DIR="${OPTS_ROOT[2]}"
    fi
    if [[ -n $OPTS_SECTION_WIDTH ]]; then
        SECTION_WIDTH="${OPTS_SECTION_WIDTH[2]}"
    fi
    if [[ -n $OPTS_MAJOR_WIDTH ]]; then
        MAJOR_WIDTH="${OPTS_MAJOR_WIDTH[2]}"
    fi
    if [[ -n $OPTS_MAJOR_TOP_LINES ]]; then
        MAJOR_TOP_LINES="${OPTS_MAJOR_TOP_LINES[2]}"
    fi

    if [[ -z $HEADER_LINES || ! $HEADER_LINES =~ '^[0-9]+$' ]]; then
        echo "Invalid -n/--header-lines value: ${HEADER_LINES}"
        return 1
    fi
    if [[ -z $TOP_N || ! $TOP_N =~ '^[0-9]+$' ]]; then
        echo "Invalid -t/--top value: ${TOP_N}"
        return 1
    fi
    if [[ -z $ROOT_DIR || ! -d $ROOT_DIR ]]; then
        echo "Invalid -r/--root dir: ${ROOT_DIR}"
        return 1
    fi
    if [[ -z $SECTION_WIDTH || ! $SECTION_WIDTH =~ '^[0-9]+$' ]]; then
        echo "Invalid -s/--section-width value: ${SECTION_WIDTH}"
        return 1
    fi
    if [[ -z $MAJOR_WIDTH || ! $MAJOR_WIDTH =~ '^[0-9]+$' ]]; then
        echo "Invalid -m/--major-width value: ${MAJOR_WIDTH}"
        return 1
    fi
    if [[ -z $MAJOR_TOP_LINES || ! $MAJOR_TOP_LINES =~ '^[0-9]+$' ]]; then
        echo "Invalid -M/--major-top-lines value: ${MAJOR_TOP_LINES}"
        return 1
    fi

    (( $+functions[_loading] )) && _loading "Code audit: divider '=' widths" || echo "[code-audit] divider '=' widths"
    (( $+functions[_loading2] )) && _loading2 "Root: ${ROOT_DIR}" || echo "Root: ${ROOT_DIR}"
    (( $+functions[_loading2] )) && _loading2 "Header lines: ${HEADER_LINES} | Top N: ${TOP_N}" || echo "Header lines: ${HEADER_LINES} | Top N: ${TOP_N}"
    (( $+functions[_loading2] )) && _loading2 "Suggested standard: section=${SECTION_WIDTH} major=${MAJOR_WIDTH}" || echo "Suggested standard: section=${SECTION_WIDTH} major=${MAJOR_WIDTH}"

    typeset -a FILES
    FILES=(${(@f)$(command find "${ROOT_DIR}" -type f -name '*.zsh' 2>/dev/null)})

    if (( ${#FILES[@]} == 0 )); then
        echo "No .zsh files found under ${ROOT_DIR}"
        return 1
    fi

    if [[ -n $OPTS_FIX ]]; then
        typeset -i DRY_RUN=0
        [[ -n $OPTS_DRY_RUN ]] && DRY_RUN=1

        (( $+functions[_loading] )) && _loading "Normalizing '=' divider widths" || echo "Normalizing '=' divider widths"
        (( $+functions[_loading2] )) && _loading2 "Major: ${MAJOR_WIDTH} '=' (top ${MAJOR_TOP_LINES} lines), Section: ${SECTION_WIDTH} '='" || echo "Major: ${MAJOR_WIDTH} '=' (top ${MAJOR_TOP_LINES} lines), Section: ${SECTION_WIDTH} '='"
        (( DRY_RUN )) && (( $+functions[_warning] )) && _warning "Dry-run enabled: no files will be modified" || true

        typeset -i changed_count=0
        typeset -i file_count=0
        typeset file tmp

        for file in "${FILES[@]}"; do
            (( file_count++ ))
            tmp="${TMPDIR:-/tmp}/zshbop_code_audit_fix_${$}_${RANDOM}"

            command awk \
                -v section_width="${SECTION_WIDTH}" \
                -v major_width="${MAJOR_WIDTH}" \
                -v major_top_lines="${MAJOR_TOP_LINES}" \
                '
                function rep(n,    i, r) { r=""; for (i=0; i<n; i++) r=r "="; return r }
                {
                    raw=$0
                    line=raw
                    sub(/^#[[:space:]]*/, "", line)
                    gsub(/[[:space:]]/, "", line)

                    if (line ~ /^=+$/) {
                        target=section_width
                        if (NR <= major_top_lines) {
                            target=major_width
                        } else if (length(line) >= 70) {
                            target=major_width
                        }
                        print "# " rep(target)
                    } else {
                        print raw
                    }
                }
                ' "$file" > "$tmp" 2>/dev/null

            if ! command cmp -s "$file" "$tmp" 2>/dev/null; then
                (( changed_count++ ))
                if (( DRY_RUN )); then
                    (( $+functions[_log] )) && _log "Would update: $file" || echo "Would update: $file"
                    command rm -f "$tmp" 2>/dev/null
                else
                    command mv "$tmp" "$file"
                fi
            else
                command rm -f "$tmp" 2>/dev/null
            fi
        done

        if (( DRY_RUN )); then
            echo "Dry-run complete: ${changed_count}/${file_count} files would change"
        else
            echo "Fix complete: ${changed_count}/${file_count} files changed"
        fi

        # Re-run audit output after fix unless JSON requested
        [[ -n $OPTS_JSON ]] && return 0
        echo ""
    fi

    typeset HEADER_COUNTS FUNC_COUNTS TOTAL_COUNTS

    HEADER_COUNTS=$(command awk -v header_lines="${HEADER_LINES}" '
        FNR<=header_lines {
            line=$0
            sub(/^#[[:space:]]*/, "", line)
            gsub(/[[:space:]]/, "", line)
            if (line ~ /^=+$/) print length(line)
        }
    ' "${FILES[@]}" | command sort -n | command uniq -c | command sort -nr)

    TOTAL_COUNTS=$(command awk '
        {
            line=$0
            sub(/^#[[:space:]]*/, "", line)
            gsub(/[[:space:]]/, "", line)
            if (line ~ /^=+$/) print length(line)
        }
    ' "${FILES[@]}" | command sort -n | command uniq -c | command sort -nr)

    FUNC_COUNTS=$(command awk '
        FNR==1 { dash_nr=-9999; last_div_len=-1; last_div_nr=-9999 }
        {
            raw=$0
            if (raw ~ /^#[[:space:]]*--[[:space:]]*/) {
                dash_nr=FNR
                if (last_div_nr > 0 && (FNR - last_div_nr) <= 2) {
                    print last_div_len
                }
            }

            line=raw
            sub(/^#[[:space:]]*/, "", line)
            gsub(/[[:space:]]/, "", line)
            if (line ~ /^=+$/) {
                len=length(line)
                if ((FNR - dash_nr) >= 0 && (FNR - dash_nr) <= 2) {
                    print len
                }
                last_div_len=len
                last_div_nr=FNR
            }
        }
    ' "${FILES[@]}" | command sort -n | command uniq -c | command sort -nr)

    typeset MODE_HEADER_W MODE_HEADER_C MODE_FUNC_W MODE_FUNC_C MODE_TOTAL_W MODE_TOTAL_C
    MODE_HEADER_C=$(echo "${HEADER_COUNTS}" | command awk 'NR==1{print $1; exit}' 2>/dev/null)
    MODE_HEADER_W=$(echo "${HEADER_COUNTS}" | command awk 'NR==1{print $2; exit}' 2>/dev/null)
    MODE_FUNC_C=$(echo "${FUNC_COUNTS}" | command awk 'NR==1{print $1; exit}' 2>/dev/null)
    MODE_FUNC_W=$(echo "${FUNC_COUNTS}" | command awk 'NR==1{print $2; exit}' 2>/dev/null)
    MODE_TOTAL_C=$(echo "${TOTAL_COUNTS}" | command awk 'NR==1{print $1; exit}' 2>/dev/null)
    MODE_TOTAL_W=$(echo "${TOTAL_COUNTS}" | command awk 'NR==1{print $2; exit}' 2>/dev/null)

    typeset HEADER_TOTAL FUNC_TOTAL TOTAL_TOTAL
    HEADER_TOTAL=$(echo "${HEADER_COUNTS}" | command awk '{s+=$1} END{print s+0}')
    FUNC_TOTAL=$(echo "${FUNC_COUNTS}" | command awk '{s+=$1} END{print s+0}')
    TOTAL_TOTAL=$(echo "${TOTAL_COUNTS}" | command awk '{s+=$1} END{print s+0}')

    if [[ -n $OPTS_JSON ]]; then
        echo "{\"files\":${#FILES[@]},\"header_lines\":${HEADER_LINES},\"dividers\":{\"header\":${HEADER_TOTAL},\"func\":${FUNC_TOTAL},\"total\":${TOTAL_TOTAL}},\"modes\":{\"header\":{\"width\":${MODE_HEADER_W:-0},\"count\":${MODE_HEADER_C:-0}},\"func\":{\"width\":${MODE_FUNC_W:-0},\"count\":${MODE_FUNC_C:-0}},\"total\":{\"width\":${MODE_TOTAL_W:-0},\"count\":${MODE_TOTAL_C:-0}}}}"
        return 0
    fi

    echo "Scanned ${#FILES[@]} files"
    echo "Divider lines found (only '=' dividers): header=${HEADER_TOTAL} | func-proximity=${FUNC_TOTAL} | total=${TOTAL_TOTAL}"
    echo ""

    echo "Script headers (first ${HEADER_LINES} lines): mode=${MODE_HEADER_W:-none} (${MODE_HEADER_C:-0})"
    echo "${HEADER_COUNTS}" | command head -n "${TOP_N}" | command awk '{printf("  width=%s count=%s\n", $2, $1)}'
    echo ""

    echo "Function/section headers (near '# --' lines): mode=${MODE_FUNC_W:-none} (${MODE_FUNC_C:-0})"
    echo "${FUNC_COUNTS}" | command head -n "${TOP_N}" | command awk '{printf("  width=%s count=%s\n", $2, $1)}'
    echo ""

    echo "All '=' dividers: mode=${MODE_TOTAL_W:-none} (${MODE_TOTAL_C:-0})"
    echo "${TOTAL_COUNTS}" | command head -n "${TOP_N}" | command awk '{printf("  width=%s count=%s\n", $2, $1)}'
}
