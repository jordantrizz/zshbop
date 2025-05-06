# ==================================================
# domain commands
# ==================================================
_debug " -- Loading ${(%):-%N}"
typeset -gA help_domain
help_files[domain]="Domain Name functions and commands."

# -- domaincheck
help_domain[domaincheck]='Check if a domain name is available'
alias domaincheck="domaincheck.sh"

# -- bin/domain-info
help_domain[domain-info]='Check a domains name servers and www and a record and print them out'

# --- dom
help_domain[dom]='Check a domains availability, www, mx etc'
function dom () {
    # Check if dig and whois are present
    _cmd_exists dig
    [[ $? -eq 1 ]] && { _error "dig is not installed"; return 1; }
    _cmd_exists whois
    [[ $? -eq 1 ]] && { _error "whois is not installed"; return 1; }
    
    local DOMAIN="$1"
    # -- Check if domain is set
    [[ -z $DOMAIN ]] && _error1 "Please specify a domain name"        

    # -- Strip domain name
    DOMAIN_CLEAN=$(domain-strip $DOMAIN 1)

    # -- Check if domain is valid
    [[ $DOMAIN =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] || _error1 "Invalid domain name"
    domain $DOMAIN_CLEAN

    _loading "Checking $DOMAIN_CLEAN"
    if [[ $? -eq 0 ]]; then    
        echo ""
        domain-info $DOMAIN_CLEAN
        echo ""
        domain-spf $DOMAIN_CLEAN
        echo ""
        domain-dmarc $DOMAIN_CLEAN 0
    fi

}

# ==========================================
# -- dom-strip
# ==========================================
help_domain[dom-strip]='Strip a domain name to the base domain if email or :// is present'
function dom-strip () {
    local DOMAIN="$1"
    # Check if email, and strip domain out
    if [[ $DOMAIN == *"@"* ]]; then
        _loading "Detected email address, stripping domain"
        DOMAIN=$(echo $DOMAIN | cut -d "@" -f 2)        
    # Check if https:// or http:// is present and strip out
    elif [[ $DOMAIN == *"http"* ]]; then
        _loading "Detected http:// or https://, stripping out"
        DOMAIN=$(echo $DOMAIN | cut -d "/" -f 3)
    else
        _debugf "No email or http:// or https:// detected, using domain as is"
    fi

    # -- Check if domain is valid
    if [[ $DOMAIN =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        _debugf "Domain is valid"
    else
        _error1 "Invalid domain name"
    fi
    
    echo $DOMAIN
}

#=========================================
# -- dom-cf
#=========================================
help_domain[dom-cf]='Check domain on Cloudflare when proxied'
dom-cf () {
    # -- _dom-cf-api $ENDPOINT
    _dom-cf-api () {
        local CURL_EXIT_CODE ENDPOINT CURL_OUTPUT 
        ENDPOINT="$1"
        _debugf "ENDPOINT: $ENDPOINT"        
        [[ $DEBUGF == "1" ]] && set -x
        CURL_OUTPUT="$(mktemp)"        
        CURL_EXIT_CODE=$(curl -s --output $CURL_OUTPUT -w "%{http_code}" \
        -X GET "https://api.cloudflare.com${ENDPOINT}" \
        -H "X-Auth-Email: $CF_ACCOUNT" \
        -H "X-Auth-Key: $CF_KEY" \
        -H "Content-Type: application/json")
        local API_OUTPUT=$(<"$CURL_OUTPUT")
        _debugf "CURL_EXIT_CODE: $CURL_EXIT_CODE"
        _debugf "API_OUTPUT: $API_OUTPUT"
        rm "$CURL_OUTPUT"
        [[ $DEBUGF == "1" ]] && set +x
        if [[ $CURL_EXIT_CODE == "200" ]]; then
            echo "$API_OUTPUT"
        else
            _error "Error from API: $CURL_EXIT_CODE"
            return 1
        fi
    }
    _dom-cf-print-records () {
        local JSON_RECORDS="$1"
        local RECORD_NAME RECORD_TYPE RECORD_CONTENT
        for RECORDS in $JSON_RECORDS; do
            if [[ -n "$RECORDS" ]]; then
                RECORD_NAME=$(echo "$RECORDS" | jq -r '.name')
                RECORD_TYPE=$(echo "$RECORDS" | jq -r '.type')
                RECORD_CONTENT=$(echo "$RECORDS" | jq -r '.content')
                echo "$RECORD_NAME -> $RECORD_TYPE -> $RECORD_CONTENT"
            else
                _debugf "No records found"
            fi
        done    
    }

    local CF_API_KEY CF_API_EMAIL DOMAIN="$1" DOMAIN_ID
    CF_CONFIG="$HOME/.cloudflare"
    [[ ! -f $CF_CONFIG ]] && { _error "Cloudflare API key file not found, please create $CF_CONFIG"; return 1; }
    source $CF_CONFIG
    if [[ -z $CF_ACCOUNT ]] &&  { _error "CF_ACCOUNT not set, please check $CF_CONFIG"; return 1; }
    if [[ -z $CF_KEY ]] &&  { _error "CF_KEY not set, please check $CF_CONFIG"; return 1; }

    _loading "Checking $DOMAIN on Cloudflare"
    # -- Check if domain is set
    [[ -z $DOMAIN ]] && { _error "Please specify a domain name"; return 1; }
    
    # -- Strip domain name
    DOMAIN_CLEAN=$(domain-strip $DOMAIN 1)
    [[ $? -eq 1 ]] && { _error "Error stripping domain name"; return 1; }

    # -- List Domain records for @ and www
    CURL_OUTPUT=$(mktemp)
    DOMAIN_ID=$(_dom-cf-api "/client/v4/zones?name=$DOMAIN_CLEAN" | jq -r '.result[0].id')
    _debugf "DOMAIN_ID: $DOMAIN_ID"
    if [[ -z $DOMAIN_ID ]]; then
        _error "Domain ID not found on Cloudflare"
        return 1
    else
        echo "$DOMAIN -> DOMAIN_ID: $DOMAIN_ID"
    fi

    # -- Get domain records
    ALL_RECORDS=$(_dom-cf-api "/client/v4/zones/$DOMAIN_ID/dns_records?per_page=100")
    _debugf "ALL_RECORDS: $ALL_RECORDS"

    # -- Get Apex record, filter on type A and CNAME, there might be multiple
    APEX_RECORD=$(echo $ALL_RECORDS | jq -r '.result[] | select(.name == "'$DOMAIN_CLEAN'" and (.type == "A" or .type == "CNAME"))')
    _debugf "APEX_RECORD: $APEX_RECORD"
    if [[ -z $APEX_RECORD ]]; then
        _error1 "Apex record not found on Cloudflare"
        return 1
    else     
        _dom-cf-print-records "$APEX_RECORD"        
    fi
    
    # -- Get www record
    WWW_RECORD=$(echo $ALL_RECORDS | jq -r '.result[] | select(.name == "www.'$DOMAIN_CLEAN'")')
    _debugf "WWW_RECORD: $WWW_RECORD"
    if [[ -z $WWW_RECORD ]]; then
        _error1 "www record not found on Cloudflare"
        return 1
    else
        _dom-cf-print-records "$WWW_RECORD"
    fi
}

# ============================================
# -- domain-info
# =============================================
help_domain[domain-info]='Check a domains name servers and www and a record and print them out'
function domain-info () {
    _domain_info_usage () {
        echo "Usage: domain-info [-c] <domain name>"
        echo "Options:"
        echo "-c       - Compact output."
    }

    # -- get_nameservers
    _domain_info_get_nameservers () {
        local NAMESERVERS DOMAIN="$1" NS
        NAMESERVERS=($(dig +short NS $DOMAIN))
        for NS in "${NAMESERVERS[@]}"; do            
            if $(echo $NS | grep -Eq "([a-z]+\.ns\.cloudflare\.com)"); then
                echo -n "$bg[yellow]$fg[black]CF${reset_color} - $NS "                
            else
                echo -n "$NS "
            fi        
        done
        echo "\n"
    }

    # -- get_apex
    _domain_info_get_record () {
        local RECORD="$1"
        local IPS=$(dig +short $RECORD)
        local TEXT=""    
        # Go through IPS which might contain a CNAME and IP's or just IP's
        # We need to make sure the IP's have a comma after them if they have multiple
        IPS_ARRAY=("${(f)IPS}")
        LAST_INDEX=$(( ${#IPS_ARRAY[@]}))
        for INDEX in {1..$#IPS_ARRAY}; do
            IP=${IPS_ARRAY[$INDEX]}
            # -- Check if first is an IP or CNAME
            if $(echo $IP | grep -Eq "([0-9]{1,3}[\.]){3}[0-9]{1,3}"); then
                if $(cf-ip -q $IP); then
                    TEXT+="$IP = $bg[yellow]$fg[black]CF${reset_color} "
                else
                    TEXT+="$IP"
                fi
                # If this is not the last IP, append a comma
                if [[ $INDEX -ne $LAST_INDEX ]]; then
                    TEXT+=", "
                fi
            else
                TEXT+="$RECORD = $bg[green]$fg[black]CNAME${reset_color} "                
            fi
        done
        echo $TEXT
    }

    _domain_info_get_mx () {
        local DOMAIN="$1"
        local MX_TEXT 
        MX_TEXT=()        
        RECORD=$(dig +short MX $DOMAIN)
        TEXT=""    
        for MX in "${(f)RECORD}"; do
            MX_TEXT+=($MX)
        done
        echo "${MX_TEXT[@]}"
    }

    # -------
    # -- main
    # -------
    zparseopts -D -E c=COMPACT
    local DOMAIN="$1"

    if [[ -z $DOMAIN ]]; then
        _domain_info_usage
        _error "Please specifiy a domain"
        return
    fi

    _loading "Getting domain name DNS information for $DOMAIN"
    APEX_TEXT=$(_domain_info_get_record $DOMAIN)
    WWW_TEXT=$(_domain_info_get_record www.$DOMAIN)
    MX_TEXT=$(_domain_info_get_mx $DOMAIN)    

    if [[ $COMPACT ]]; then        
        echo "Nameservers: $(_domain_info_get_nameservers $DOMAIN)"                
        echo -n " $bg[red]$fg[black]||||||${reset_color} APEX@: $APEX_TEXT"
        echo -n " $bg[red]$fg[black]||||||${reset_color} WWW.: $WWW_TEXT"
    else
        _loading2 "Domain: $DOMAIN"
        echo "Nameservers: $(_domain_info_get_nameservers $DOMAIN)"            
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

# ==========================================
# -- domain
# ==========================================
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

    domain-strip $DOMAIN_INPUT 1 >> /dev/null
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
    local DOMAIN_INPUT="$1" QUIET=${2:="0"}
    
    [[ $QUIET == 0 ]] && _loading "Checking $DOMAIN_INPUT and stripping any extra characters"
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

    domain-strip "$DOMAIN" 1 >> /dev/null
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
    domain-strip $DOMAIN 1 >> /dev/null
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