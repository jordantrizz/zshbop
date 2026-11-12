#!/usr/bin/env zsh
# -------------------------------------------------------------------------------------------------
# -- scripts/docs/lib.sh -- shared helpers for the docs generators
# -------------------------------------------------------------------------------------------------
# Sourced by gen-commands.sh, gen-kb.sh, gen-changelog.sh, and gen-readme.sh. Nothing here writes to
# the site on its own.
# -------------------------------------------------------------------------------------------------

REPO_URL="https://github.com/jordantrizz/zshbop"
SITE_URL="https://jordantrizz.github.io/zshbop"

# ==============================================
# -- humanize - turn a slug into a page title
# -- "mysql-int" -> "MySQL internals", "aws" -> "AWS"
# ==============================================
humanize () {
    local slug=$1 word out=""
    local -a words
    words=(${(s:-:)slug})
    for word in "${words[@]}"; do
        case $word in
            aws) word="AWS" ;;
            ssl) word="SSL" ;;
            ssh) word="SSH" ;;
            dns) word="DNS" ;;
            ip) word="IP" ;;
            php) word="PHP" ;;
            mysql) word="MySQL" ;;
            mysqldumper) word="MySQLDumper" ;;
            m365) word="M365" ;;
            whmcs) word="WHMCS" ;;
            csf) word="CSF" ;;
            nmap) word="Nmap" ;;
            nginx) word="Nginx" ;;
            redis) word="Redis" ;;
            traefik) word="Traefik" ;;
            proxmox) word="Proxmox" ;;
            docksoft) word="Docksoft" ;;
            wordpress) word="WordPress" ;;
            github) word="GitHub" ;;
            git) word="Git" ;;
            litespeed) word="LiteSpeed" ;;
            openssl) word="OpenSSL" ;;
            postmark) word="Postmark" ;;
            slack) word="Slack" ;;
            powershell) word="PowerShell" ;;
            runcloud) word="RunCloud" ;;
            cloudflare) word="Cloudflare" ;;
            raid) word="RAID" ;;
            cve) word="CVE" ;;
            int) word="internals" ;;
            bin) word="binaries" ;;
            os) word="OS" ;;
            zsh) word="Zsh" ;;
            bash) word="Bash" ;;
            0) word="" ;;
            *) word="${(C)word}" ;;
        esac
        [[ -n $word ]] && out+="${out:+ }$word"
    done
    print -r -- "$out"
}

# ==============================================
# -- replace_block - rewrite one GENERATED block in place
# -- replace_block <file> <marker-name> <items-file>
# Lines between "BEGIN GENERATED: <name>" and "END GENERATED: <name>" are replaced with the contents
# of <items-file>; everything else in the file is preserved byte for byte.
# ==============================================
replace_block () {
    local file=$1 name=$2 items=$3 tmp
    tmp=$(mktemp)
    awk -v name="$name" -v items="$items" '
        index($0, "BEGIN GENERATED: " name) {
            print
            while ((getline line < items) > 0) print line
            close(items)
            skip = 1
            next
        }
        index($0, "END GENERATED: " name) { skip = 0 }
        !skip { print }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
}

# ==============================================
# -- yaml_escape - make a string safe for a double-quoted YAML scalar
# ==============================================
yaml_escape () {
    local text=$1
    text=${text//\\/}
    text=${text//\"/}
    print -r -- "$text"
}

# ==============================================
# -- first_description - first prose line of a markdown file
# -- Fence-aware: skips fenced blocks, headings, tables, lists, and quotes. A line that starts with
# -- ``` but also contains the run again is inline code, not a fence.
# ==============================================
first_description () {
    awk '
        {
            line = $0
            sub(/^[ \t]+/, "", line)
            if (line ~ /^(```|~~~)/) {
                run = (line ~ /^```/) ? "```" : "~~~"
                rest = substr(line, 4)
                if (index(rest, run) == 0) fence = !fence
                next
            }
            if (fence) next
            if (line == "") next
            if (line ~ /^(#|\||\*|-|>)/) next
            if (line ~ /^[A-Za-z0-9_`<"]/) { print line; exit }
        }
    ' "$1"
}

# ==============================================
# -- article_body - the source without its leading H1
# ==============================================
article_body () {
    awk '
        !done && /^# / { done = 1; next }
        { print }
    ' "$1"
}

# ==============================================
# -- demote_headings - push every heading down one level, outside fences
# -- The page's front-matter title owns the h1, so an article's own h1 becomes h2.
# -- Reads stdin when no file is given.
# ==============================================
demote_headings () {
    awk '
        {
            line = $0
            probe = line
            sub(/^[ \t]+/, "", probe)
            if (probe ~ /^(```|~~~)/) {
                run = (probe ~ /^```/) ? "```" : "~~~"
                rest = substr(probe, 4)
                if (index(rest, run) == 0) fence = !fence
                print
                next
            }
            if (!fence && line ~ /^#{1,5} /) line = "#" line
            print line
        }
    ' "${1:--}"
}

# ==============================================
# -- trim_description - strip markdown and cut to a search-result length
# ==============================================
trim_description () {
    local text=$1
    local bt='`' lp='(' rp=')' lb='[' rb=']' star='*'
    text=${text//$bt/}
    text=${text//$star/}
    text=${text//$lb/}
    text=${text//$rb/}
    text=${text//$lp/}
    text=${text//$rp/}
    text=${text//  / }
    (( ${#text} > 160 )) && text="${text[1,157]}..."
    print -r -- "$text"
}
