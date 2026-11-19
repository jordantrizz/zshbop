#!/usr/bin/env zsh
# -------------------------------------------------------------------------------------------------
# -- scripts/docs/gen-kb.sh -- mirror the shell knowledge base into the docs site
# -------------------------------------------------------------------------------------------------
# kb/ is the runtime source: `kb <article>` reads $ZSHBOP_ROOT/kb/<article>.md. This script writes a
# mirror to website/docs/kb/ so the site and the shell cannot drift, adds the front matter the site
# needs, and regenerates the knowledge-base index and its sidebar block.
#
# Nothing under kb/ is modified. When an article cannot be rendered here, fix the article.
# -------------------------------------------------------------------------------------------------
set -euo pipefail
export LC_ALL=C

DOCS=${0:A:h}
source "$DOCS/lib.sh"

ROOT=${DOCS:h:h}
SRC="$ROOT/kb"
OUT="$ROOT/website/docs/kb"
SIDEBAR="$ROOT/website/sidebars.ts"

mkdir -p "$OUT"

local -a names titles summaries
local file name title desc body count=0
for file in "$SRC"/*.md; do
    name=${${file:t}%.md}
    # The title is the article name as the shell knows it (`kb docker`), not the first heading:
    # several articles open with a section heading such as "Common Commands".
    title=$(humanize "$name")
    desc=$(first_description "$file" || true)
    if [[ -n $desc ]]; then
        desc=$(trim_description "$desc")
    else
        desc="Knowledge base article on $title. Also available in the shell as \`kb $name\`."
    fi
    names+=("$name")
    titles+=("$title")
    summaries+=("$desc")

    {
        print -r -- '---'
        print -r -- "title: $(yaml_escape "$title")"
        print -r -- "description: \"$(yaml_escape "$desc")\""
        print -r -- '---'
        print -r -- ''
        print -r -- "<!-- BEGIN GENERATED: kb-$name -->"
        article_body "$file" | demote_headings
        print -r -- ''
        print -r -- "---"
        print -r -- ''
        print -r -- "*Generated from [\`kb/$name.md\`]($REPO_URL/blob/next-release/kb/$name.md) by"
        print -r -- "\`npm run gen:kb\`. The shell shows the same article with \`kb $name\`.*"
        print -r -- ''
        print -r -- "<!-- END GENERATED: kb-$name -->"
    } > "$OUT/$name.md"
    count=$(( count + 1 ))
done

# ==============================================
# -- knowledge base index
# ==============================================
{
    print -r -- '---'
    print -r -- 'title: Knowledge base'
    print -r -- 'description: The articles shipped with zshbop, readable here or in the shell with kb <article>.'
    print -r -- '---'
    print -r -- ''
    print -r -- '<!-- BEGIN GENERATED: kb-index -->'
    print -r -- ':::info[Generated page]'
    print -r -- 'These articles live in `kb/` and are what the `kb` command reads: `kb docker` opens the'
    print -r -- 'Docker article in your pager. This page is a generated mirror — edit the article in `kb/`,'
    print -r -- 'not the copy here.'
    print -r -- ':::'
    print -r -- ''
    print -r -- "| Article | Summary |"
    print -r -- "|---------|---------|"
    local i
    for (( i = 1; i <= ${#names}; i++ )); do
        local summary=${summaries[i]}
        summary=${summary//\|/\\|}
        print -r -- "| [${titles[i]}](./${names[i]}.md) | ${summary} |"
    done
    print -r -- ''
    print -r -- '<!-- END GENERATED: kb-index -->'
} > "$OUT/index.md"

# ==============================================
# -- sidebar block
# ==============================================
local items
items=$(mktemp)
{
    print -r -- "        'kb/index',"
    printf '%s\n' "${names[@]}" | sort | while IFS= read -r name; do
        [[ -n $name ]] && print -r -- "        'kb/$name',"
    done
} > "$items"
replace_block "$SIDEBAR" sidebars-kb "$items"
rm -f "$items"

print -r -- "gen-kb: $count articles mirrored, index and sidebar regenerated"
