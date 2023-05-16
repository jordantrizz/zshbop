#!/usr/bin/env zsh
# -- include zbr core
source ${ZBR}/zshbop.zsh

# -- Cloudflare IPS
        CLOUDFLARE_IPS=(
        "173.245.48.0/20"
        "103.21.244.0/22"
        "103.22.200.0/22"
        "103.31.4.0/22"
        "141.101.64.0/18"
        "108.162.192.0/18"
        "190.93.240.0/20"
        "188.114.96.0/20"
        "197.234.240.0/22"
        "198.41.128.0/17"
        "162.158.0.0/15"
        "104.16.0.0/13"
        "104.24.0.0/14"
        "172.64.0.0/13"
        "131.0.72.0/22"
        "198.41.128.0/17"
        "2400:cb00::/32"
        "2606:4700::/32"
        "2803:f800::/32"
        "2c0f:f248::/32"
        "2a06:98c0::/29"
        )

usage () {
    echo "\
Usage: domain-info [-c] <domain name>

  Options:
      -c       - Compact output.
"
}

# -- get_nameservers
get_nameservers () {
    NAMESERVERS=($(dig +short NS $DOMAIN))
}

# -- is_cloudflare
is_cloudflare () {
    local IS_CF
    if [[ $(echo $NAMESERVERS | grep -Eq "([a-z]+\.ns\.cloudflare\.com)") ]]; then
        IS_CF=1
    else
        IS_CF=0
    fi
}

# -- get_apex
get_record () {
    RECORD="$1"    
    RECORD=$(dig +short $RECORD)
    TEXT=""    
    for IP in "${(f)RECORD}"; do
        if [[ $(grepcidr3 -D "$IP" <(echo "$CLOUDFLARE_IPS")) ]]; then
            TEXT+="$IP = $bg[yellow]$fg[black]CF${reset_color} "
        else
            TEXT+="$IP"
        fi
    done
    echo $TEXT
}

get_mx () {
    RECORD="$1"
    RECORD=$(dig +short MX $RECORD)
    TEXT=""    
    for MX in "${(f)RECORD}"; do
        MX_TEXT+=($MX)
    done
}

# -------
# -- main
# -------
zparseopts -D -E c=COMPACT
DOMAIN="$1"

if [[ -z $DOMAIN ]]; then
    usage
    _error "Please specifiy a domain"
    exit
fi

# Get nameservers
get_nameservers
is_cloudflare
APEX_TEXT=$(get_record $DOMAIN)
WWW_TEXT=$(get_record www.$DOMAIN)
get_mx $DOMAIN

if [[ $COMPACT ]]; then
    _loading2 "$DOMAIN - Nameservers: ${(f)NAMESERVERS}"
    if [[ $IS_CF ]]; then echo -n " = $bg[yellow]$fg[black]CF${reset_color}"; fi
    echo -n " $bg[red]$fg[black]||||||${reset_color} APEX@: $APEX_TEXT"
    echo -n " $bg[red]$fg[black]||||||${reset_color} WWW.: $WWW_TEXT"
else
    _loading "Domain: $DOMAIN"    
    echo -n " Nameservers:"     
    if [[ $IS_CF ]]; then echo " - $bg[yellow]$fg[black]Cloudflare Nameservers${reset_color}"; fi    
    echo " ${NAMESERVERS}"
    echo ""
    _loading2 "DNS Records"
    echo " APEX@: $APEX_TEXT"
    echo " WWW.: $WWW_TEXT"
    echo " MX:"
    for item in $MX_TEXT; do
        echo "   - ${item}"
    done     
fi
echo ""