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
    fi
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
    echo ""

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