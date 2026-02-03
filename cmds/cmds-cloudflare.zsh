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
    local QUIET=${1:=0}

    function _cf_update_ip_list_do () {
        local QUIET="$1"
        [[ $QUIET == "0" ]] && _running "Getting Cloudflare IP addresses"
        curl -s https://www.cloudflare.com/ips-v4 > $HOME/tmp/cloudflare-ips.txt
        curl -s https://www.cloudflare.com/ips-v6 >> $HOME/tmp/cloudflare-ips.txt
        [[ $QUIET == "0" ]] && _success "Cloudflare IP addresses saved to $HOME/tmp/cloudflare-ips.txt"
    }
    # -- Check if files are older than 1 week
    if [[ -f $HOME/tmp/cloudflare-ips.txt ]]; then
        if [[ $(find $HOME/tmp/cloudflare-ips.txt -mtime +7 -print) ]]; then        
            _cf_update_ip_list_do            
        else
            [[ $QUIET == "0" ]] && _success "Cloudflare IP addresses already exist in $HOME/tmp/cloudflare-ips.txt"
        fi
    else
        _cf_update_ip_list_do $QUIET
    fi
}

# -- cf-ip -- Check if passed IP is a CF IP
# -- Usage: ./cf-ip [-q] <ip>
help_cloudflare[cf-ip]='Check if passed IP is a CF IP'
function cf-ip () {
    zparseopts -D -E q=ARG_QUIET
    local IP=$1 QUIET
    [[ -n $ARG_QUIET ]] && QUIET=1 || QUIET=0
    
    # -- Check IP
    function _cf_ip_checkinput () {
        local QUIET="$1"
        [[ $QUIET == 0 ]] && _loading3 "Checking if $IP is an IP or Domain"

        # -- Check if $IP is ip or domain
        local IPV4_REGEX='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
        
        # Regex for IPv6 address (basic validation)
        local IPV6_REGEX='^([0-9a-fA-F]{0,4}:){2,7}([0-9a-fA-F]{0,4})$'

        # Regex for domain (basic validation)
        local DOMAIN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$'

        if [[ $IP =~ $IPV4_REGEX ]]; then
            _debug "$IP is an IPv4 address."
        elif [[ $IP =~ $IPV6_REGEX ]]; then
            _debug "$IP is an IPv6 address."
        elif [[ $IP =~ $DOMAIN_REGEX ]]; then
            DOMAIN=$IP
            IP=$(dig +short $IP)
            _debug "$DOMAIN is a domain, resolved to $IP"
        else
            _error "Unknown format for $IP"
            return 1
        fi
    }

    function _cf_ip_check_ip () {
        local QUIET="$1"
        # -- Check if IP is a Cloudflare IP using grepcidr3        
        GREPCIDR3=$(grepcidr3 -D $IP <(cat $HOME/tmp/cloudflare-ips.txt))        
        if [[ -n $GREPCIDR3 ]]; then        
            [[ $QUIET == "0" ]] && _success "$IP is a Cloudflare IP matched $GREPCIDR3"
            return 0
        else
            [[ $QUIET == "0" ]] && _error "$IP is not a Cloudflare IP"
            return 1
        fi
    }


    # -- Check if IP is passed
    if [[ -z $IP ]]; then
        _error "Usage: ./cf-ip (-q) <ip>"
        return 1
    fi

    [[ $QUIET == "0" ]] && _loading "Checking if $IP is a Cloudflare IP"
    _cf_ip_checkinput $QUIET
    cf-update-ip-list $QUIET
    _cf_ip_check_ip $QUIET

}

function _cf_check_parsewhois () {
    local DOM="$1" DEBUG="$2" WHOIS_OUT_NS WHOIS_OUT first
    function _cf_check_debug () {
        local MSG="$1" DATA="$2"      
        if [[ -n $DEBUG ]]; then
            echo "--------------------------"
            echo "DEBUG: $MSG"
            printf '%q' "$2"
            echo ""            
        fi
    }
    NS_ARRAY=()
    WHOIS_OUT_NS_ARRAY=()

    _cf_check_debug "Parsing whois for" $DOM
    WHOIS_OUT_NS="$(whois $DOM | grep -i "Name Server:" | tr '\n' ' ')"
    _cf_check_debug "Raw Whois" $WHOIS_OUT_NS
    
    WHOIS_OUT_NS="$(echo ${WHOIS_OUT_NS//'Name Server: '/})"
    _cf_check_debug "Removed Name Server" $WHOIS_OUT_NS
    WHOIS_OUT_NS_ARRAY=($(echo $WHOIS_OUT_NS))
    _cf_check_debug "Processed #1 Array" $WHOIS_OUT_NS_ARRAY
    for NS in "${WHOIS_OUT_NS_ARRAY[@]}"; do                          
        _cf_check_debug "Processing each record as" $NS
        # -- Remove Whitespace        
        NS="${NS##*( )}"
        _cf_check_debug "Removed Whitespace" $NS

        # -- Lowercase
        NS="${NS:l}"
        _cf_check_debug "Lower case" $NS
        if $first; then
            NS_ARRAY+=("$NS")
            first=false
        else
            # -- Check if NS is already in array
            for i in "${NS_ARRAY[@]}"; do
                _cf_check_debug "Checking if $i is in array" $NS
                if [[ $i == $NS ]]; then
                    _cf_check_debug "Already in the array" $NS
                    break
                else
                    _cf_check_debug "Not in array, adding" $NS
                    NS_ARRAY+=("$NS")
                fi
            done
        fi        
    done
    NS_ARRAY=("${(@o)NS_ARRAY}")
    echo $NS_ARRAY | tr ' ' '|'
}

help_cloudflare[cf-check]='Check if a domain is using Cloudflare'
function cf-check() {
    local CSV_OUTPUT=""

    function _cf_check_domain () {
        local DIG_OUT WHOIS_OUT SUB_DOMAIN HOST ROOT_DOMAIN 
        local DIG_OUT_RESOLVES DIG_OUT_NS DIG_OUT_WWW        
        local HOST="$1"        
                
        # -- Check if domain is proxied through Cloudflare
        _loading2 "Checking if $HOST is proxied through Cloudflare"
        cfr_host="$HOST"

        # -- Check if domain name or dns name
        local DOT_COUNT=$(grep -o "\." <<< "$HOST" | wc -l)
        local DOMAIN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+([a-zA-Z]{2,63})$'
        local SUBDOMAIN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.){2,}([a-zA-Z]{2,63})$'

        # -- Check if domain or subdomain
        if [[ $DOT_COUNT -ge 2 ]]; then
            _loading3 "$HOST is a subdomain"  
            # Extract the base domain from subdomain
            ROOT_DOMAIN=$(echo $HOST | awk -F'.' '{print $(NF-1)"."$NF}')            
            SUB_DOMAIN="Yes"          
        elif [[ $DOMAIN =~ $DOMAIN_REGEX ]]; then
            _loading3 "$HOST is a top-level domain"
            ROOT_DOMAIN="$HOST"
            SUB_DOMAIN="No"
        else
            _loading3 "Invalid format for domain or DNS record - $HOST"
            return 1
        fi

        cfr_rootdomain="$ROOT_DOMAIN"
        cfr_subdomain="$SUB_DOMAIN"            

        # -- Check cloudflare nameservers via whois    
        WHOIS_OUT="$(_cf_check_parsewhois $ROOT_DOMAIN)"
        cfr_cfnswhois_out="$WHOIS_OUT"
        WHOIS_IS_CF=$(echo $WHOIS_OUT | grep -i 'cloudflare')
        if [[ -n $WHOIS_IS_CF ]]; then
            _success "Cloudflare name servers detected via WHOIS - $WHOIS_OUT"
            cfr_cfnswhois="Yes"
        else
            _error "Cloudflare name servers not detected via WHOIS - $WHOIS_OUT"
            cfr_cfnswhois="No"
        fi

        # -- Check Cloudflare name servers via dig
        DIG_OUT_NS_ARRAY=()           
        DIG_OUT_NS_TEMP=($(dig ns $ROOT_DOMAIN +short))        
        for NS in "${DIG_OUT_NS_TEMP[@]}"; do
            TEMP=${NS%\.}            
            DIG_OUT_NS_ARRAY+=("$TEMP")
        done
        DIG_OUT_NS_ARRAY=("${(@o)DIG_OUT_NS_ARRAY}")
        DIG_OUT_NS="$(echo ${DIG_OUT_NS_ARRAY[@]} | tr ' ' '|')"        
        cfr_nsdig_out=$DIG_OUT_NS
        if echo $DIG_OUT_NS | grep -iq 'cloudflare'; then
            _success "Cloudflare name servers detected via DIG - $DIG_OUT_NS"                                            
            cfr_cfnsdig="Yes"
        else
            _error "Cloudflare name servers not detected via DIG - $DIG_OUT_NS"            
            cfr_cfnsdig="No"
        fi

        # -- Check if WHOIS and DIG match
        if [[ $WHOIS_OUT == $DIG_OUT_NS ]]; then
            _success "WHOIS and DIG match"
            cfr_whoisdigns_match="Yes"
        else
            _error "WHOIS and DIG do not match"
            cfr_whoisdigns_match="No"
        fi

        # -- Host IP     
        DIG_OUT_HOST=($(dig +short $HOST))
        cfr_dighost_out="$DIG_OUT_HOST"
        if [[ -n $DIG_OUT_HOST ]]; then
            _success "$HOST= resolves - $DIG_OUT_HOST"
            cfr_dighost_out="$DIG_OUT_HOST"
        else
            _error "$HOST= does not resolve - $DIG_OUT_HOST"
            cfr_dighost_out="$DIG_OUT_HOST"        
        fi

        # Check if host record is proxied    
        for IP in "${DIG_OUT_HOST[@]}"; do
            if cf-ip "$IP" > /dev/null 2>&1; then
                _success "Apex record is proxied through Cloudflare - $IP"
                cfr_hostcf="Yes"
            else
                _error "Apex record is not proxied through Cloudflare - $IP"
                cfr_hostcf="No"
            fi
        done

        # -- Check if www record is proxied
        # Check if domain record has www. in the front
        if [[ $HOST =~ ^www\..* ]]; then
                _error "Checking www record already"
                cfr_wwwresolves="www"
                cfr_wwwcf=""
        elif [[ $SUB_DOMAIN == "Yes" ]]; then
            _loading3 "Not checking www.$HOST record as its a subdomain"
            cfr_wwwresolves="subdomain"
            cfr_wwwcf=""     
        else            
            DIG_OUT_WWW=($(dig +short www.$HOST))
            for IP in "${DIG_OUT_WWW[@]}"; do
                if cf-ip "$IP" > /dev/null 2>&1; then
                    _success "www.$HOST record is proxied through Cloudflare - $IP"
                    cfr_wwwresolves="$IP"
                    cfr_wwwcf="Yes"
                else
                    _error "www.$HOST record is not proxied through Cloudflare - $IP"
                    cfr_wwwresolves="$IP"
                    cfr_wwwcf="No"
                fi
            done
        fi

        if [[ -n $CSV ]]; then            
            _cf_add_to_csv 
        fi
    }

    function _cf_check_file () {
        FILE="$1"
        DOMAIN=""
        OUTPUT=""    
        _loading "Processing file $FILE"   

        if [[ -z $FILE ]]; then
            _cf_check_usage      
            _error "No file passed"      
            return 1
        fi

        if [[ ! -f $FILE ]]; then
            _error "File $FILE does not exist"
            return 1
        fi

        while read DOMAIN; do
            # -- If start of line contains # skip
            if [[ $DOMAIN =~ ^#.* ]]; then
                continue
            fi

            if [[ -n $CSVEXPORT ]]; then
                echo "Checking $DOMAIN"
                _cf_check_domain $DOMAIN >> /dev/null
            elif [[ -n $CSVOUTPUT ]]; then 
                echo "Checking $DOMAIN"  
                _cf_check_domain $DOMAIN >> /dev/null
            else
                _cf_check_domain $DOMAIN
            fi
            [[ -n $ARG_DELAY ]] && sleep $ARG_DELAY[2]
        done < $FILE    

    }

    function _cf_add_to_csv () {
        local CSV_LINE=""
        CSV_LINE="$cfr_host,"
        CSV_LINE+="$cfr_rootdomain,"        
        CSV_LINE+="$cfr_subdomain,"                
        CSV_LINE+="$cfr_nsdig_out,"
        CSV_LINE+="$cfr_cfnsdig,"
        CSV_LINE+="$cfr_whoisdigns_match,"

        CSV_LINE+="$cfr_dighost_out,"
        CSV_LINE+="$cfr_hostcf,"        
        CSV_LINE+="$cfr_wwwresolves,"
        CSV_LINE+="$cfr_wwwcf,"
        
        CSV_LINE+="$cfr_cfnswhois_out,"
        CSV_LINE+="$cfr_cfnswhois,"
        CSV_OUTPUT+="${CSV_LINE}\n"        
    }
    
    function _cf_check_output_csv () {             
        CSV_HEADER="Host,Root Domain,Subdomain,DIG NS,CFNS,WHOIS/DIG Match,"
        CSV_HEADER+="Host IP, Host CF, WWW IP,WWW CF,"
        CSV_HEADER+="WHOISOUT,CFWHOIS"
        CSV_OUTPUT_FINAL="${CSV_HEADER}\n"
        CSV_OUTPUT_FINAL+="${CSV_OUTPUT}\n"
        echo "$CSV_OUTPUT_FINAL"
    }

    function _cf_check_usage () {        
        echo "Usage: ./cf-check -c -co -d [<domain>|-f <file>] "
        echo "Commands:"
        echo "  -d <domain>    - Check a single domain"
        echo "  -f <file>      - Check a file of domains"
        echo "  -w <domain>    - Parse whois for domain"
        echo ""
        echo "Options:"
        echo "  -c             - Output CSV"
        echo "  -co            - Output CSV only"
        echo "  -e             - Export to CSV <file>.csv with headers"
        echo "  -p <seconds>   - Delay between checks"
        echo "  -h             - Help"        
    }
    
    local ARG_DOMAIN ARG_FILE CSVOUT CSVONLY DOMAIN FILE HELP DELAY="0" CSVEXPORT    
    zparseopts -D -E c=CSVOUT co=CSVONLY d:=ARG_DOMAIN f:=ARG_FILE h=HELP e=CSVEXPORT delay:=ARG_DELAY p:=ARG_PARSE_WHOIS

    if [[ -n $CSVOUT ]] || [[ -n $CSVONLY ]] || [[ -n CSVEXPORT ]]; then
        CSV=1
    fi

    [[ -n $ARG_DOMAIN ]] && DOMAIN=$ARG_DOMAIN[2]
    [[ -n $ARG_FILE ]] && FILE=$ARG_FILE[2] 
    [[ -n $ARG_DELAY ]] && DELAY=$ARG_DELAY[2] || DELAY="0"
    [[ -n $ARG_PARSE_WHOIS ]] && PARSE_WHOIS=$ARG_PARSE_WHOIS[2]

    if [[ -n $HELP ]]; then
        echo "Printing help"
        _cf_check_usage        
        return 0
    elif [[ -n $DOMAIN ]]; then        
        _loading "Checking domain $DOMAIN"  
        if [[ -n $CSVOUT ]]; then
            _loading2 "Outputting CSV"
            _cf_check_domain $DOMAIN
            echo ""            
            _cf_check_output_csv          
        elif [[ -n $CSVONLY ]]; then
            _loading2 "Outputting CSV Only"
            _cf_check_domain $DOMAIN >> /dev/null
            echo ""
            _cf_check_output_csv
        else
            _cf_check_domain $DOMAIN            
        fi        
    elif [[ -n $FILE ]]; then
        _loading "Checking file $FILE with delay of $DELAY seconds"
        if [[ -n $CSVOUT ]]; then
            _loading2 "Outputting CSV"
            _cf_check_file $FILE
            echo ""
            _cf_check_output_csv
        elif [[ -n $CSVONLY ]]; then
            _loading2 "Outputting CSV Only"
            _cf_check_file $FILE >> /dev/null
            echo ""
            _cf_check_output_csv
        elif [[ $CSVEXPORT ]]; then
            _loading2 "Outputting CSV to $FILE.csv"
            _cf_check_file $FILE
            echo ""
            _cf_check_output_csv > $FILE.csv
        else
            _loading "Checking file $FILE"
            _cf_check_file $FILE
        fi     
    elif [[ -n $PARSE_WHOIS ]]; then
        _loading "Parsing whois for $PARSE_WHOIS"
        _cf_check_parsewhois $PARSE_WHOIS 1
    else
        _error "No arguments"
        _cf_check_usage
        return 1
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

# =============================================================================
# -- cf-cloudflared-fixes
# =============================================================================
help_cloudflare[cf-cloudflared-fixes]='Fixes for cloudflared'
function cf-cloudflared-fixes () {
    # Set sysctl for quic udp improvements
    #sysctl -w net.core.rmem_max=7500000
    #sysctl -w net.core.wmem_max=7500000

    local CF_SYSCTL_FILE="/etc/sysctl.d/99-cloudflared.conf"

    # Create or update the sysctl configuration file for cloudflared
    _loading "Setting sysctl parameters for cloudflared in $SYSCTL_FILE"
    echo "net.core.rmem_max=7500000" | sudo tee -a $SYSCTL_FILE
    echo "net.core.wmem_max=7500000" | sudo tee -a $SYSCTL_FILE

    # Apply the new sysctl settings
    _loading2 "Applying sysctl parameters for cloudflared"
    sudo sysctl --system

    _loading2 "Sysctl parameters for cloudflared have been set and applied."
    
}
