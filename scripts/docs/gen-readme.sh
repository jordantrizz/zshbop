#!/usr/bin/env zsh
# -------------------------------------------------------------------------------------------------
# -- scripts/docs/gen-readme.sh -- write the README's docs-index pointer block
# -------------------------------------------------------------------------------------------------
# The README is a doorway to the site, not a second copy of it. The block between
# "<!-- BEGIN docs-index -->" and "<!-- END docs-index -->" is generated from the section list below;
# hand edits to it are reverted by the next run.
# -------------------------------------------------------------------------------------------------
set -euo pipefail
export LC_ALL=C

DOCS=${0:A:h}
source "$DOCS/lib.sh"

ROOT=${DOCS:h:h}
README="$ROOT/README.md"

[[ -f $README ]] || { print -ru2 -- "gen-readme: no README.md at $README"; exit 1 }

grep -qxF '<!-- BEGIN docs-index -->' "$README" || {
    print -ru2 -- "gen-readme: README.md has no '<!-- BEGIN docs-index -->' marker; add the pair first"
    exit 1
}

local tmp
tmp=$(mktemp)
{
    print -r -- '<!-- BEGIN docs-index -->'
    print -r -- '| Section | Start here |'
    print -r -- '|---------|------------|'
    print -r -- "| Getting started | [What zshbop is]($SITE_URL/getting-started/what-is-zshbop) |"
    print -r -- "| Guides | [Tab completion]($SITE_URL/guides/tab-completion) |"
    print -r -- "| Command reference | [All commands]($SITE_URL/commands) |"
    print -r -- "| Configuration | [Options and variables]($SITE_URL/reference/configuration) |"
    print -r -- "| Contributing | [Development]($SITE_URL/contributing/development) |"
    print -r -- "| Knowledge base | [Articles]($SITE_URL/kb) |"
    print -r -- "| Changelog | [Release history]($SITE_URL/history/changelog) |"
    print -r -- '<!-- END docs-index -->'
} > "$tmp"

awk -v block="$tmp" '
    /<!-- BEGIN docs-index -->/ {
        while ((getline line < block) > 0) print line
        close(block)
        skip = 1
        next
    }
    /<!-- END docs-index -->/ { skip = 0; next }
    !skip { print }
' "$README" > "$tmp.out"

mv "$tmp.out" "$README"
rm -f "$tmp"

print -r -- "gen-readme: docs-index block written to README.md"
