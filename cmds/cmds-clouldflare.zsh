# --
# cloudflare commands
#
# Example help: help_cloudflare[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_cloudflare

# What help file is this?
help_files[cloudflare]='Cloudflare Commands'

# -- cfpurge
help_cloudflare[cfpurge]='Purge single or multiple urls'

# -- cloudflare
help_cloudflare[cloudflare]='The bash cloudflare cli'
alias cf="cloudflare"

# -- cf-gws-mx
help_cloudflare[cf-gws-mx]='Create Google Workspace MX records using cf-cli'
cf-gws-mx () {
    	DOMAIN=$1
	if [[ -z $DOMAIN ]]; then
        _error "Usage: ./cf-gws-mx <domain>"
        return 1
    fi

    _running "Creating Google Workspace MX records for $DOMAIN"
    cf add record $DOMAIN MX $DOMAIN ASPMX.L.GOOGLE.COM 1 1
    cf add record $DOMAIN MX $DOMAIN ALT1.ASPMX.L.GOOGLE.COM 1 5
    cf add record $DOMAIN MX $DOMAIN ALT2.ASPMX.L.GOOGLE.COM 1 5
    cf add record $DOMAIN MX $DOMAIN ALT3.ASPMX.L.GOOGLE.COM 1 10
    cf add record $DOMAIN MX $DOMAIN ALT4.ASPMX.L.GOOGLE.COM 1 10

}

# -- cf-update-ip-list -- Get Cloudflare IP addresses and store in $HOME/tmp/cloudflare-ips.txt
help_cloudflare[cf-update-ip-list]='Get Cloudflare IP addresses'
cf-update-ip-list () {
    # -- Check if files are older than 1 week
    if [[ -f $HOME/tmp/cloudflare-ips.txt ]]; then
        if [[ $(find $HOME/tmp/cloudflare-ips.txt -mtime +7 -print) ]]; then
            _running "Getting Cloudflare IP addresses"
            curl -s https://www.cloudflare.com/ips-v4 > $HOME/tmp/cloudflare-ips.txt
            curl -s https://www.cloudflare.com/ips-v6 >> $HOME/tmp/cloudflare-ips.txt
            _success "Cloudflare IP addresses saved to $HOME/tmp/cloudflare-ips.txt"
        else
            _success "Cloudflare IP addresses already exist in $HOME/tmp/cloudflare-ips.txt"
        fi
    else
        _running "Getting Cloudflare IP addresses"
        curl -s https://www.cloudflare.com/ips-v4 > $HOME/tmp/cloudflare-ips.txt
        curl -s https://www.cloudflare.com/ips-v6 >> $HOME/tmp/cloudflare-ips.txt
        _success "Cloudflare IP addresses saved to $HOME/tmp/cloudflare-ips.txt"
    fi
}

# -- cf-ip -- Check if passed IP is a CF IP
# -- Usage: ./cf-ip [-q] <ip>
help_cloudflare[cf-ip]='Check if passed IP is a CF IP'
function cf-ip () {
    local IP=$1

    # -- Check if IP is passed
    if [[ -z $IP ]]; then
        _error "Usage: ./cf-ip <ip>"
        return 1
    fi

    _loading "Checking if $IP is a Cloudflare IP"

    # -- Check if $IP is ip or domain
    local IPV4_REGEX='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    # Regex for IPv6 address (basic validation)
    local IPV6_REGEX='^([0-9a-fA-F]{0,4}:){2,7}([0-9a-fA-F]{0,4})$'

    # Regex for domain (basic validation)
    local DOMAIN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$'

    if [[ $IP =~ $IPV4_REGEX ]]; then
        _loading3 "$IP is an IPv4 address."
    elif [[ $IP =~ $IPV6_REGEX ]]; then
        _loading3 "$IP is an IPv6 address."
    elif [[ $IP =~ $DOMAIN_REGEX ]]; then
        DOMAIN=$IP
        IP=$(dig +short $IP)
        _loading3 "$DOMAIN is a domain, resolved to $IP"
    else
        _error "Unknown format."
    fi

    # -- Check if cloudflare-ips.txt exists and is updated
    cf-update-ip-list

    # -- Check if IP is a Cloudflare IP using grepcidr3
    GREPCIDR3=$(grepcidr3 -D $IP <(cat $HOME/tmp/cloudflare-ips.txt))
    if [[ -n $GREPCIDR3 ]]; then
        _success "$IP is a Cloudflare IP matched $GREPCIDR3"
        return 0
    else
        _error "$IP is not a Cloudflare IP"
        return 1
    fi
}

help_cloudflare[cf-check]='Check if a domain is using Cloudflare'
function cf-check() {
    local DOMAIN="$1" DIG_OUT WHOIS_OUT SUB_DOMAIN REAL_DOMAIN

    if [[ -z $DOMAIN ]]; then
        _error "Usage: ./cf-check <domain>"
        return 1
    fi

    # -- Check if domain is proxied through Cloudflare
    _loading "Checking if $DOMAIN is proxied through Cloudflare"

    # -- Check if domain name or dns name
    local DOT_COUNT=$(grep -o "\." <<< "$DOMAIN" | wc -l)
    local DOMAIN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+([a-zA-Z]{2,63})$'
    local SUBDOMAIN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.){2,}([a-zA-Z]{2,63})$'

    if [[ $DOT_COUNT -ge 2 ]]; then
        _loading3 "$DOMAIN is a subdomain or DNS record"
        # Extract the base domain from subdomain
        REAL_DOMAIN=$(echo $DOMAIN | awk -F'.' '{print $(NF-1)"."$NF}')
        SUB_DOMAIN=1
    elif [[ $DOMAIN =~ $DOMAIN_REGEX ]]; then
        _loading3 "$DOMAIN is a top-level domain"
        REAL_DOMAIN=$DOMAIN
    else
        _loading3 "Invalid format for domain or DNS record - $DOMAIN"
        return 1
    fi

    # -- Check cloudflare nameservers via whois
    _loading3 "Checking if $REAL_DOMAIN uses Cloudflare name servers via whois"
    WHOIS_OUT=($(whois $REAL_DOMAIN | grep -i "cloudflare.com"))
    if [[ -n $WHOIS_OUT ]]; then
        _success "Cloudflare name servers detected - $WHOIS_OUT"
    else
        _error "Cloudflare name servers not detected - $WHOIS_OUT"
    fi

    # Check Cloudflare name servers via dig
    _loading3 "Checking if $REAL_DOMAIN uses Cloudflare name servers via dig"
    DIG_OUT=($(dig ns $REAL_DOMAIN +short))
    if echo $DIG_OUT | grep -iq 'cloudflare'; then
        _success "Cloudflare name servers detected - $DIG_OUT"
    else
        _error "Cloudflare name servers not detected - $DIG_OUT"
    fi

    # -- Does $DOMAIN resolve?
    _loading3 "Checking if $DOMAIN resolves"
    DIG_OUT=($(dig +short $DOMAIN))
    if [[ -n $DIG_OUT ]]; then
        _success "$DOMAIN resolves - $DIG_OUT"
    else
        _error "$DOMAIN does not resolve - $DIG_OUT"
        return 1
    fi

    # Check if apex record is proxied
    _loading2 "Checking if apex record for $DOMAIN is proxied..."
    DIG_OUT=($(dig +short $DOMAIN))
    for IP in "${DIG_OUT[@]}"; do
        if cf-ip "$IP" > /dev/null 2>&1; then
            _success "Apex record is proxied through Cloudflare - $IP"
        else
            _error "Apex record is not proxied through Cloudflare - $IP"
        fi
    done

    # -- Check if www record is proxied
    # Check if domain record has www. in the front
    if [[ $DOMAIN =~ ^www\..* ]]; then
            _error "Checking www record already"
    elif [[ $SUB_DOMAIN == "1" ]]; then
        _loading3 "Not checking www.$DOMAIN record as $DOMAIN is a subdomain"
    else
        _loading2 "Checking if www.$DOMAIN record for $DOMAIN is proxied..."
        DIG_OUT=($(dig +short www.$DOMAIN))
        for IP in "${DIG_OUT[@]}"; do
            if cf-ip "$IP" > /dev/null 2>&1; then
                _success "www.$DOMAIN record is proxied through Cloudflare - $IP"
            else
                _error "www.$DOMAIN record is not proxied through Cloudflare - $IP"
            fi
        done
    fi

}

# -- cf-check-file -- Check domains conatined within a file
# -- Usage: ./cf-check-file <file>
help_cloudflare[cf-check-file]='Check domains conatined within a file'
function cf-check-file() {
    local FILE="$1" DOMAIN

    if [[ -z $FILE ]]; then
        _error "Usage: ./cf-check-file <file>"
        return 1
    fi

    if [[ ! -f $FILE ]]; then
        _error "File $FILE does not exist"
        return 1
    fi

    while read DOMAIN; do
        cf-check $DOMAIN
    done < $FILE
}

