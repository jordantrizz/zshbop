# --
# domain commands
#
# Example help: help_domain[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_domain

# What help file is this?
help_files[domain]="Domain Name functions and commands."

# -- domaincheck
help_domain[domaincheck]='Check if a domain name is available'
alias domaincheck="domaincheck.sh"

# -- bin/domain-info
help_domain[domain-info]='Check a domains name servers and www and a record and print them out'

# --- dom
help_domain[dom]='Check a domains availability, www, mx etc'
function dom () {
    local DOMAIN="$1"
    domain $1    
    if [[ $? -eq 0 ]]; then    
        echo ""
        domain-info $1
        echo ""
        domain-spf $1
        echo ""
        domain-dmarc $1 0
    fi

}

# -- domain-info
help_domain[domain-info]='Check a domains name servers and www and a record and print them out'
function domain-info () {
    # -- Cloudflare IPS
    local CLOUDFLARE_IPS=(
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

    _domain_info_usage () {
        echo "\
    Usage: domain-info [-c] <domain name>

    Options:
        -c       - Compact output.
    "
    }

    # -- get_nameservers
    _domain_info_get_nameservers () {
        NAMESERVERS=($(dig +short NS $DOMAIN))
    }

    # -- is_cloudflare
    _domain_info_is_cloudflare () {
        local IS_CF
        if [[ $(echo $NAMESERVERS | grep -Eq "([a-z]+\.ns\.cloudflare\.com)") ]]; then
            IS_CF=1
        else
            IS_CF=0
        fi
    }

    # -- get_apex
    _domain_info_get_record () {
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

    _domain_info_get_mx () {
        MX_TEXT=()
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
    _domain_info_get_nameservers
    _domain_info_is_cloudflare
    APEX_TEXT=$(_domain_info_get_record $DOMAIN)
    WWW_TEXT=$(_domain_info_get_record www.$DOMAIN)
    _domain_info_get_mx $DOMAIN

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
}

# -- domain
help_domain[domain]='Check if a domain is available.'
function domain () {
    _domain_usage () {
        echo "Usage: domaincheck (domain.ext|-a domain)"
        echo "Check if a domain name is available. Enter in the full domain name"
        echo  "  -a    - check all domain extensions, just enter the first part"    
    }
    local DOMAIN DOMAIN_INPUT="$1" CHECK_DOMAIN DOMAIN_EXTS WHOIS_DOMAIN GET_REGISTRAR="0" WHOIS_OUT

    # -- No args print usage
    if [[ -z $1 ]]; then
        _domain_usage
        return 1
    fi

    domain-strip $DOMAIN_INPUT >> /dev/null
    DOMAIN=$OUTPUT_DOMAIN_STRIP

    # -- Check all domain extensions
    _loading "Checking $DOMAIN"
    if [[ $1 == "-a" ]]; then
        _loading3  "Checking all domain extensions"
        CHECK_DOMAIN="2"
        DOMAIN_EXTS=('.com' '.co.uk' '.net' '.info' '.mobi')
        DOMAIN_EXTS+=('.org' '.tel' '.biz' '.tv' '.cc' '.eu' '.ru')
        DOMAIN_EXTS+=('.in' '.it' '.sk' '.com.au')
    else
        _loading3 "Checking single domain $DOMAIN"
        CHECK_DOMAIN="1"
    fi

    # -- Check if domain is available
    WHOIS_OUT=$(whois $DOMAIN)
    if [[ $CHECK_DOMAIN == "1" ]]; then
        
        WHOIS_DOMAIN=$(echo $WHOIS_OUT | egrep -q '^No match|^NOT FOUND|^Not fo|AVAILABLE|^No Data Fou|has not been regi|No entri')        
        if [[ $? -eq 0 ]]; then
            echo -e "Registration Status $bg[green] > ${DOMAIN}: Available to Register < ${RSC}"
            return 1
        else 
            echo "Registration Status : $bg[red]X ${DOMAIN}: Registered X ${RSC}"
            GET_REGISTRAR=1
        fi        
    elif [[ $CHECK_DOMAIN == "2" ]]; then
        echo "Checking name $2 on $DOMAIN_EXTS"
        ELEMENTS=${#DOMAIN_EXTS[@]}
        while (( "$#" )); do
            for (( i=1; i<=$ELEMENTS; i++ )); do
                WHOIS_DOMAIN=$(whois ${DOMAINS[${i}]} | egrep -q '^No match|^NOT FOUND|^Not fo|AVAILABLE|^No Data Fou|has not been regi|No entri')
                if [ $? -eq 0 ]; then
                    echo -e "$1${DOMAIN_EXTS[$i]} : ${GREEN} > Available to Register < ${NC}"
                else
                    echo "$1${DOMAIN_EXTS[$i]} : ${RED}X Registered X ${NC}"
                    GET_REGISTRAR=1
                fi                    
            done
        shift
        done
    fi

    # -- Get Domain Name Registrar
    if [[ $GET_REGISTRAR -eq 1 ]]; then
        DOMAIN_REGISTRAR="$(echo $WHOIS_OUT | egrep -i 'Registrar:' | head -1)"
        DOMAIN_REGISTRAR="${DOMAIN_REGISTRAR#"${DOMAIN_REGISTRAR%%[![:space:]]*}"}"
        echo "$DOMAIN_REGISTRAR"

        DOMAIN_REGISTRAR_URL="$(echo $WHOIS_OUT | egrep -i 'Registrar URL:' | head -1)"
        DOMAIN_REGISTRAR_URL="${DOMAIN_REGISTRAR_URL#"${DOMAIN_REGISTRAR_URL%%[![:space:]]*}"}"
        echo "$DOMAIN_REGISTRAR_URL"

        DOMAIN_CREATED="$(echo $WHOIS_OUT | egrep -i 'Creation Date:' | head -1)"
        DOMAIN_CREATED="${DOMAIN_CREATED#"${DOMAIN_CREATED%%[![:space:]]*}"}"
        echo "$DOMAIN_CREATED"

        DOMAIN_EXPIRY="$(echo $WHOIS_OUT | egrep -i 'Expiry Date:' | head -1)"
        DOMAIN_EXPIRY="${DOMAIN_EXPIRY#"${DOMAIN_EXPIRY%%[![:space:]]*}"}"
        echo "$DOMAIN_EXPIRY"

    fi
    echo ""
}

# ----------------------------------------------------------------------------------------------------
# -- domain-strip $domain $quiet
# --
# -- Strip a domain name to the base domain
# -- Example: domain-strip "https://www.google.com" -> google.com
# -- Echos and Sets: OUTPUT_DOMAIN_STRIP
# ----------------------------------------------------------------------------------------------------
help_domain[domain-strip]='Strip a domain name to the base domain'
function domain-strip () {
    local QUIET=${2:="0"} DOMAIN_INPUT="$1"
    
    _loading "Checking $DOMAIN_INPUT and stripping any extra characters"
    # -- Check if https:// is in the domain name

    [[ $DOMAIN_INPUT == *"https://"* ]] && { DOMAIN_INPUT=${DOMAIN_INPUT#"https://"}; [[ $QUIET=="0" ]] && _loading3 "Stripped https://"; }
    # -- Check if http:// is in the domain name
    [[ $DOMAIN_INPUT == *"http://"* ]] && { DOMAIN_INPUT=${DOMAIN_INPUT#"http://"}; _loading3 "Stripped http://"; }
    # -- Check if www is in the domain name
    [[ $DOMAIN_INPUT == *"www."* ]] && { DOMAIN_INPUT=${DOMAIN_INPUT#"www."}; _loading3 "Stripped www"; }
    # -- Remove / with anything else past /
    [[ $DOMAIN_INPUT == *"/"* ]] && { DOMAIN_INPUT=${DOMAIN_INPUT%%/*}; _loading3 "Stripped /"; }
    # -- Remove anything after a space
    [[ $DOMAIN_INPUT == *" "* ]] && { DOMAIN_INPUT=${DOMAIN_INPUT%% *}; _loading3 "Stripped space"; }    
    
    # -- echo and set
    echo $DOMAIN_INPUT
    OUTPUT_DOMAIN_STRIP="$DOMAIN_INPUT"
}

# -- domain-dmarc
help_domain[domain-dmarc]='Check a domains dmarc record'
function domain-dmarc () {
    local DOMAIN="$1" EXTENDED="${2:=1}"

    domain-strip $DOMAIN >> /dev/null
    DOMAIN=$OUTPUT_DOMAIN_STRIP

    _loading "Checking $DOMAIN for DMARC record"
    DMARC_RECORD=$(dig +short TXT _dmarc.$DOMAIN | tr -d '"')
    if [[ -z $DMARC_RECORD ]]; then
        _error "No DMARC record found for $DOMAIN"
    else
        _success "DMARC record found for $DOMAIN"        
        echo "$DMARC_RECORD"    
        echo ""

        if [[ $EXTENDED == "1" ]]; then
            _loading "Breaking down DMARC record"
            CONFIGS=()
            CONFIGS=("${(@s/;/)DMARC_RECORD}")
            KEYS=("v" "pct" "rua" "ruf" "p" "sp" "adkim" "aspf" "fo")
            for KEY in "${KEYS[@]}"; do
                FOUND=false
                for CONFIG in "${CONFIGS[@]}"; do
                    CONFIG="${CONFIG#"${CONFIG%%[![:space:]]*}"}" # remove leading whitespace
                    CONFIG_KEY="${CONFIG%%=*}"
                    VALUE="${CONFIG#*=}"
                    if [[ "$CONFIG_KEY" == "$KEY" ]]; then
                        FOUND=true
                        case "$KEY" in
                            "v") _green "Version v=DMARC1:${RSC} $VALUE" ;;
                            "pct") _green "Percentage pct=:${RSC} $VALUE" ;;
                            "rua") _green "Aggregate Report rua=:${RSC} $VALUE" ;;
                            "ruf") _green "Forensic Report ruf=:${RSC} $VALUE" ;;
                            "p") _green "Policy p=(none|quarantine|reject):${RSC} $VALUE" ;;
                            "sp") _green "Subdomain Policy sp=:${RSC} $VALUE" ;;
                            "adkim") _green "Policy ADKIM adkim=:${RSC} $VALUE" ;;
                            "aspf") _green "Policy ASPF aspf=:${RSC} $VALUE" ;;
                            "fo") _green "Policy FO fo=:${RSC} $VALUE" ;;
                        esac
                        break
                    fi
                done        
                if [[ "$FOUND" == false ]]; then                        
                    _yellow "\t$KEY missing"
                fi
            done
            echo ""
            _loading "DMARC Tools"
            echo "DMARC Policy Validator: https://vamsoft.com/support/tools/dmarc-policy-validator"
        fi
    fi
}

# -- domain-spf
help_domain[domain-spf]='Check a domains spf record'
function domain-spf () {
    local DOMAIN="$1"
    domain-strip $DOMAIN >> /dev/null
    DOMAIN=$OUTPUT_DOMAIN_STRIP

    _loading "Checking $DOMAIN for SPF record"
    SPF_RECORD=$(dig +short TXT $DOMAIN | grep 'v=spf1')
    if [[ -z $SPF_RECORD ]]; then
        _error "No SPF record found for $DOMAIN"
    else
        _success "SPF record found for $DOMAIN"
        echo "$SPF_RECORD"
    fi    

}