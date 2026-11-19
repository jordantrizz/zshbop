#!/usr/bin/env zsh
# -------------------------------------------------------------------------------------------------
# -- scripts/docs/gen-commands.sh -- generate the command reference
# -------------------------------------------------------------------------------------------------
# Every user-facing command is registered in a help_<category>[<command>]='<description>' array. This
# script reads those arrays and writes:
#   website/docs/commands/index.md       one row per category
#   website/docs/commands/<slug>.md      one page per cmds/cmds-<slug>.zsh
#   website/docs/commands/os.md           cmds/os-*.zsh (linux, mac, wsl), grouped by array
#   website/docs/commands/zshbop.md       lib/*.zsh (core, zb, quick), grouped by array
#   website/docs/commands/checks.md       checks/checks-*.zsh, grouped by file
#   website/sidebars.ts                   the sidebars-commands block
#
# Internal helpers (names starting with "_") and the help_files/help_int/help_* metadata arrays are
# not commands and are never emitted. Output is deterministic: sorted by command name, no timestamps.
# -------------------------------------------------------------------------------------------------
set -euo pipefail
export LC_ALL=C

DOCS=${0:A:h}
source "$DOCS/lib.sh"

ROOT=${DOCS:h:h}
OUT="$ROOT/website/docs/commands"
SIDEBAR="$ROOT/website/sidebars.ts"

mkdir -p "$OUT"

# ==============================================
# -- parse_help - array<TAB>command<TAB>description from one or more source files
# -- Skips help_files (a file description, not a command) and "_" internal helpers.
# ==============================================
parse_help () {
    local file
    {
        for file in "$@"; do
            sed -nE "s/^help_([a-z_]+)\[([^]]+)\]=['\"](.*)['\"][[:space:]]*(#.*)?$/\1\t\2\t\3/p" "$file"
        done
    } | awk -F'\t' '
        $1 == "files" { next }
        $2 ~ /^_/ { next }
        {
            sub(/[[:space:]]+$/, "", $3)
            gsub(/\|/, "\\|", $3)
            print $1 "\t" $2 "\t" $3
        }
    ' | sort -t$'\t' -k2,2
}

# ==============================================
# -- array_label - heading for an aggregated page section
# ==============================================
array_label () {
    case $1 in
        core) print -r -- 'Core commands' ;;
        zshbop) print -r -- 'zb commands' ;;
        zshbop_quick) print -r -- 'Quick commands' ;;
        linux) print -r -- 'Linux' ;;
        mac) print -r -- 'macOS' ;;
        wsl) print -r -- 'WSL' ;;
        *) humanize "${1//_/-}" ;;
    esac
}

# ==============================================
# -- write_table - rows (command<TAB>description) as a markdown table
# ==============================================
write_table () {
    local rows=$1
    print -r -- '| Command | Description |'
    print -r -- '|---------|-------------|'
    print -r -- "$rows" | while IFS=$'\t' read -r cmd desc; do
        [[ -n $cmd ]] && print -r -- "| \`$cmd\` | $desc |"
    done
}

# ==============================================
# -- write_page - one category page for a single source file
# ==============================================
write_page () {
    local slug=$1 title=$2 file=$3 rows=$4 n=$5
    local rel=${file#"$ROOT"/}
    {
        print -r -- '---'
        print -r -- "title: $(yaml_escape "$title")"
        print -r -- "description: \"Commands registered in $rel ($n), generated from its help entries.\""
        print -r -- '---'
        print -r -- ''
        print -r -- "<!-- BEGIN GENERATED: commands-$slug -->"
        print -r -- ':::info[Generated page]'
        print -r -- "Generated from [\`$rel\`]($REPO_URL/blob/next-release/$rel) by \`npm run gen:commands\`. Edit"
        print -r -- 'the `help_*` entries in the source file, not this page.'
        print -r -- ':::'
        print -r -- ''
        if [[ -z $rows ]]; then
            print -r -- 'No commands are registered in this file yet.'
        else
            write_table "$rows"
        fi
        print -r -- ''
        print -r -- "<!-- END GENERATED: commands-$slug -->"
    } > "$OUT/$slug.md"
}

# ==============================================
# -- write_aggregate - one page whose sections come from several files, grouped by help array
# -- write_aggregate <slug> <title> <description> <label-for-source> <skip-arrays> <files...>
# ==============================================
write_aggregate () {
    local slug=$1 title=$2 desc=$3 source_label=$4 skip=",$5,"
    shift 5
    local -a files
    files=("$@")
    local parsed array rows
    parsed=$(parse_help "${files[@]}")
    {
        print -r -- '---'
        print -r -- "title: $(yaml_escape "$title")"
        print -r -- "description: \"$desc\""
        print -r -- '---'
        print -r -- ''
        print -r -- "<!-- BEGIN GENERATED: commands-$slug -->"
        print -r -- ':::info[Generated page]'
        print -r -- "Generated from $source_label by \`npm run gen:commands\`. Edit the \`help_*\` entries"
        print -r -- 'in the source files, not this page. Internal helpers (names starting with `_`) and'
        print -r -- 'internal help arrays are omitted.'
        print -r -- ':::'
        for array in ${(u)${(f)parsed}%%$'\t'*}; do
            [[ -z $array ]] && continue
            [[ $skip == *",$array,"* ]] && continue
            rows=$(print -r -- "$parsed" | awk -F'\t' -v a="$array" '$1 == a { print $2 "\t" $3 }')
            print -r -- ''
            print -r -- "## $(array_label "$array")"
            print -r -- ''
            write_table "$rows"
        done
        print -r -- ''
        print -r -- "<!-- END GENERATED: commands-$slug -->"
    } > "$OUT/$slug.md"
}

# ==============================================
# -- category pages, one per cmds/cmds-*.zsh
# ==============================================
local -a slugs titles counts
local file slug title rows n
for file in "$ROOT"/cmds/cmds-*.zsh; do
    slug=${${file:t}#cmds-}
    slug=${slug%.zsh}
    title=$(humanize "$slug")
    rows=$(parse_help "$file" | cut -f2,3)
    n=$(print -r -- "$rows" | grep -c . || true)
    write_page "$slug" "$title" "$file" "$rows" "$n"
    slugs+=("$slug")
    titles+=("$title")
    counts+=("$n")
done

# ==============================================
# -- OS commands, grouped by array (linux, mac, wsl)
# ==============================================
local os_files
os_files=("$ROOT"/cmds/os-*.zsh)
write_aggregate os 'Operating system commands' \
    'Linux, macOS, and WSL commands from cmds/os-*.zsh, grouped by platform.' \
    '`cmds/os-*.zsh`' int "${os_files[@]}"
local os_count
os_count=$(parse_help "${os_files[@]}" | grep -c . || true)

# ==============================================
# -- zshbop's own commands, grouped by array (core, zb, quick)
# ==============================================
local lib_files
lib_files=("$ROOT"/lib/*.zsh)
write_aggregate zshbop 'zshbop commands' \
    'The core commands and the zb command family from lib/, grouped by help array.' \
    '`lib/*.zsh`' int,checks "${lib_files[@]}"
local zb_count
zb_count=$(parse_help "${lib_files[@]}" | grep -c . || true)

# ==============================================
# -- environment checks
# ==============================================
local checks="$OUT/checks.md" checkfile check_slug check_title check_rows check_n
local checks_total=0
{
    print -r -- '---'
    print -r -- 'title: Environment checks'
    print -r -- 'description: Every environment check registered in checks/, grouped by the file that defines it.'
    print -r -- '---'
    print -r -- ''
    print -r -- '<!-- BEGIN GENERATED: commands-checks -->'
    print -r -- ':::info[Generated page]'
    print -r -- 'Generated from `checks/checks-*.zsh` by `npm run gen:commands`. Edit the `help_checks`'
    print -r -- 'entries in the source files, not this page.'
    print -r -- ':::'
    for checkfile in "$ROOT"/checks/checks-*.zsh; do
        check_slug=${${checkfile:t}#checks-}
        check_slug=${check_slug%.zsh}
        check_title=$(humanize "$check_slug")
        check_rows=$(parse_help "$checkfile" | cut -f2,3)
        check_n=$(print -r -- "$check_rows" | grep -c . || true)
        checks_total=$(( checks_total + check_n ))
        print -r -- ''
        print -r -- "## $check_title"
        print -r -- ''
        print -r -- "Source: [\`checks/${checkfile:t}\`]($REPO_URL/blob/next-release/checks/${checkfile:t}) — $check_n checks."
        print -r -- ''
        write_table "$check_rows"
    done
    print -r -- ''
    print -r -- '<!-- END GENERATED: commands-checks -->'
} > "$checks"

# ==============================================
# -- index page
# ==============================================
{
    print -r -- '---'
    print -r -- 'title: Command reference'
    print -r -- 'description: Every user-facing command registered in zshbop help arrays, grouped by the file that defines it.'
    print -r -- '---'
    print -r -- ''
    print -r -- '<!-- BEGIN GENERATED: commands-index -->'
    print -r -- ':::info[Generated page]'
    print -r -- 'Generated from the `help_*` arrays by `npm run gen:commands`. Every user-facing command is'
    print -r -- 'registered there, so this is the complete list — run `help <category>` in the shell for the'
    print -r -- 'same entries. Internal helpers are omitted.'
    print -r -- ':::'
    print -r -- ''
    print -r -- '| Category | Commands |'
    print -r -- '|----------|----------|'
    print -r -- "| [zshbop commands](./zshbop.md) | $zb_count |"
    print -r -- "| [Operating system commands](./os.md) | $os_count |"
    local i
    for (( i = 1; i <= ${#slugs}; i++ )); do
        print -r -- "| [${titles[i]}](./${slugs[i]}.md) | ${counts[i]} |"
    done
    print -r -- "| [Environment checks](./checks.md) | $checks_total |"
    print -r -- ''
    print -r -- '<!-- END GENERATED: commands-index -->'
} > "$OUT/index.md"

# ==============================================
# -- sidebar block
# ==============================================
local items
items=$(mktemp)
{
    print -r -- "        'commands/index',"
    print -r -- "        'commands/zshbop',"
    print -r -- "        'commands/os',"
    print -r -- "        'commands/checks',"
    print -rl -- "${slugs[@]}" | sort | while IFS= read -r slug; do
        [[ -n $slug ]] && print -r -- "        'commands/$slug',"
    done
} > "$items"
replace_block "$SIDEBAR" sidebars-commands "$items"
rm -f "$items"

print -r -- "gen-commands: ${#slugs} category pages, os, zshbop, checks, index ($(( ${#slugs} + 4 )) pages)"
