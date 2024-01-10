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
    local CSV_OUTPUT="" 

    function _cf_check_usage () {
        echo "Usage: ./cf-check -c -co -d [<domain>|-f <file>] "
        echo "  -d  <domain> - Check a single domain"
        echo "  -f  <file> - Check a file of domains"
        echo "  -c  - Output CSV"
        echo "  -co - Output CSV only"
        echo "  -e  - Export to CSV <file>.csv with headers"
    }

    function _cf_check_domain () {
        local DIG_OUT WHOIS_OUT SUB_DOMAIN REAL_DOMAIN 
        local DIG_OUT_RESOLVES DIG_OUT_NS DIG_OUT_WWW
        local DOMAIN="$1"

        cfr_domain="$DOMAIN"
                
        # -- Check if domain is proxied through Cloudflare
        _loading2 "Checking if $DOMAIN is proxied through Cloudflare"

        # -- Check if domain name or dns name
        local DOT_COUNT=$(grep -o "\." <<< "$DOMAIN" | wc -l)
        local DOMAIN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+([a-zA-Z]{2,63})$'
        local SUBDOMAIN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.){2,}([a-zA-Z]{2,63})$'

        if [[ $DOT_COUNT -ge 2 ]]; then        
            # Extract the base domain from subdomain
            REAL_DOMAIN=$(echo $DOMAIN | awk -F'.' '{print $(NF-1)"."$NF}')
            SUB_DOMAIN=1            
        elif [[ $DOMAIN =~ $DOMAIN_REGEX ]]; then
            _loading3 "$DOMAIN is a top-level domain"
            REAL_DOMAIN="$DOMAIN"
            SUB_DOMAIN=0
        else
            _loading3 "Invalid format for domain or DNS record - $DOMAIN"
            return 1
        fi

        # -- Add to array
        cfr_realdomain="$REAL_DOMAIN"
        cfr_subdomain="$SUB_DOMAIN"            

        # -- Check cloudflare nameservers via whois    
        WHOIS_OUT=$(whois $REAL_DOMAIN | grep -i "cloudflare.com" | tr '\n' ' ')
        WHOIS_OUT=${WHOIS_OUT//'Name Server: '/}        
        cfr_cfnswhois_out="$WHOIS_OUT"
        if [[ -n $WHOIS_OUT ]]; then
            _success "Cloudflare name servers detected via WHOIS - $WHOIS_OUT"
            cfr_cfnswhois="1"
        else
            _error "Cloudflare name servers not detected via WHOIS - $WHOIS_OUT"
            cfr_cfnswhois="0"
        fi

        # Check Cloudflare name servers via dig    
        DIG_OUT_NS_TEMP=($(dig ns $REAL_DOMAIN +short))        
        for dom in "${DIG_OUT_NS_TEMP[@]}"; do
            TEMP=${dom%\.}            
            DIG_OUT_NS+="$TEMP "
        done 
        cfr_cfnsdig_out="$DIG_OUT_NS"
        if echo $DIG_OUT_NS | grep -iq 'cloudflare'; then
            _success "Cloudflare name servers detected via DIG - $DIG_OUT_NS"                                            
            cfr_cfnsdig=1
        else
            _error "Cloudflare name servers not detected via DIG - $DIG_OUT_NS"            
            cfr_cfnsdig=0
        fi

        # -- Check if WHOIS and DIG match
        if [[ $WHOIS_OUT == $DIG_OUT_NS ]]; then
            _success "WHOIS and DIG match"
            cfr_cfwhoisdigns_match=1
        else
            _error "WHOIS and DIG do not match"
            cfr_cfwhoisdigns_match=0
        fi

        # -- Does apex $DOMAIN resolve?        
        DIG_OUT_RESOLVES=($(dig +short $DOMAIN))
        cfr_digresolves_out="$DIG_OUT_RESOLVES"
        if [[ -n $DIG_OUT_RESOLVES ]]; then
            _success "$DOMAIN resolves - $DIG_OUT_RESOLVES"
            cfr_apexresolves=1
        else
            _error "$DOMAIN does not resolve - $DIG_OUT_RESOLVES"
            cfr_apexresolves=0            
        fi

        # Check if apex record is proxied    
        for IP in "${DIG_OUT_RESOLVES[@]}"; do
            if cf-ip "$IP" > /dev/null 2>&1; then
                _success "Apex record is proxied through Cloudflare - $IP"
                cfr_apexcf=1
            else
                _error "Apex record is not proxied through Cloudflare - $IP"
                cfr_apexcf=0
            fi
        done

        # -- Check if www record is proxied
        # Check if domain record has www. in the front
        if [[ $DOMAIN =~ ^www\..* ]]; then
                _error "Checking www record already"
                cfr_wwwresolves="www"
        elif [[ $SUB_DOMAIN == "1" ]]; then
            _loading3 "Not checking www.$DOMAIN record as $DOMAIN is a subdomain"
            cfr_wwwresolves="subdomain"            
        else            
            DIG_OUT_WWW=($(dig +short www.$DOMAIN))
            for IP in "${DIG_OUT_WWW[@]}"; do
                if cf-ip "$IP" > /dev/null 2>&1; then
                    _success "www.$DOMAIN record is proxied through Cloudflare - $IP"
                    cfr_wwwresolves=1
                    cfr_wwwcf="$IP"
                else
                    _error "www.$DOMAIN record is not proxied through Cloudflare - $IP"
                    cfr_wwwresolves=0
                    cfr_wwwcf="$IP"
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
            if [[ -n $CSVEXPORT ]]; then
                echo "Checking $DOMAIN"
                _cf_check_domain $DOMAIN >> /dev/null
            elif [[ -n $CSVOUTPUT ]]; then 
                echo "Checking $DOMAIN"  
                _cf_check_domain $DOMAIN >> /dev/null
            else
                _cf_check_domain $DOMAIN
            fi
            sleep 5
        done < $FILE    

    }

    function _cf_add_to_csv () {
        local CSV_LINE=""
        CSV_LINE="$cfr_domain,"
        CSV_LINE+="$cfr_realdomain,"        
        CSV_LINE+="$cfr_subdomain,"
        CSV_LINE+="$cfr_cfnswhois_out,"
        CSV_LINE+="$cfr_cfnswhois,"
        CSV_LINE+="$cfr_cfnsdig_out,"
        CSV_LINE+="$cfr_cfnsdig,"
        CSV_LINE+="$cfr_cfwhoisdigns_match,"
        CSV_LINE+="$cfr_digresolves_out,"
        CSV_LINE+="$cfr_apexresolves,"
        CSV_LINE+="$cfr_apexcf,"
        CSV_LINE+="$cfr_wwwresolves,"
        CSV_LINE+="$cfr_wwwcf"            
        CSV_OUTPUT+="${CSV_LINE}\n"              
    }
    
    function _cf_check_output_csv () {             
        CSV_HEADER="Domain,Real Domain,Subdomain,WHOIS NS,CFWHOIS,DIG NS,CFNS,WHOIS and DIG Match,DIG Resolves Out,Apex Resolves Out,Apex CF,WWW Resolves Out,WWW CF"
        CSV_OUTPUT_FINAL="${CSV_HEADER}\n"
        CSV_OUTPUT_FINAL+="${CSV_OUTPUT}\n"
        echo "$CSV_OUTPUT_FINAL"
    }

    local ARG_DOMAIN ARG_FILE CSVOUT CSVONLY DOMAIN FILE HELP
    zparseopts -D -E c=CSVOUT co=CSVONLY d:=ARG_DOMAIN f:=ARG_FILE h=HELP e=CSVEXPORT

    if [[ -n $CSVOUT ]] || [[ -n $CSVONLY ]] || [[ -n CSVEXPORT ]]; then
        CSV=1
    fi

    [[ -n $ARG_DOMAIN ]] && DOMAIN=$ARG_DOMAIN[2]
    [[ -n $ARG_FILE ]] && FILE=$ARG_FILE[2]   

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
        if [[ -n $CSVOUT ]]; then
            _loading2 "Outputting CSV"
            _cf_check_file $FILE
            echo ""
            _cf_check_output_csv
        elif [[ -n $CSVONLY ]]; then
            _loading2 "Outputting CSV Only"
            _cf_check_file $FILE
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

