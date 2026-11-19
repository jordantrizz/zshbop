#!/usr/bin/env zsh
# -------------------------------------------------------------------------------------------------
# -- scripts/docs/gen-changelog.sh -- mirror CHANGELOG.md into the docs site
# -------------------------------------------------------------------------------------------------
# CHANGELOG.md stays at the repository root (the release workflow expects it there). The site page is
# a mirror of that curated file — not a log rebuilt from git, which would change on every release
# commit and prove nothing.
# -------------------------------------------------------------------------------------------------
set -euo pipefail
export LC_ALL=C

DOCS=${0:A:h}
source "$DOCS/lib.sh"

ROOT=${DOCS:h:h}
SRC="$ROOT/CHANGELOG.md"
OUT="$ROOT/website/docs/history/changelog.md"

[[ -f $SRC ]] || { print -ru2 -- "gen-changelog: no CHANGELOG.md at $SRC"; exit 1 }

{
    print -r -- '---'
    print -r -- 'title: Changelog'
    print -r -- 'description: Every notable change to zshbop, newest first. Mirrored from CHANGELOG.md in the repository root.'
    print -r -- '---'
    print -r -- ''
    print -r -- '<!-- BEGIN GENERATED: changelog -->'
    print -r -- ':::info[Generated page]'
    print -r -- 'Mirrored from [`CHANGELOG.md`]('"$REPO_URL"'/blob/next-release/CHANGELOG.md) by'
    print -r -- '`npm run gen:changelog`. Add entries to the root file, never here.'
    print -r -- ':::'
    print -r -- ''
    awk '!done && /^# / { done = 1; next } { print }' "$SRC"
    print -r -- ''
    print -r -- '<!-- END GENERATED: changelog -->'
} > "$OUT"

print -r -- "gen-changelog: wrote ${OUT#"$ROOT/"}"
