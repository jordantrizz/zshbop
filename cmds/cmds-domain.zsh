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
    domain $1
    domain-info $1
}

# -- domain
help_domain[domain]='Check if a domain is available.'
function domain () {
    _domain_usage () {
        echo "Usage: domaincheck (domain.ext|-a domain)"
        echo "Check if a domain name is available. Enter in the full domain name"
        echo  "  -a    - check all domain extensions, just enter the first part"    
    }
    local DOMAIN="$1" CHECK_DOMAIN DOMAIN_EXTS WHOIS_DOMAIN GET_REGISTRAR="0" WHOIS_OUT

    # -- No args print usage
    if [[ -z $1 ]]; then
        _domain_usage
        return 1
    fi

    # -- Check all domain extensions
    _loading "Checking $DOMAIN"
    if [[ $1 == "-a" ]]; then
        echo " - Checking all domain extensions"
        CHECK_DOMAIN="2"
        DOMAIN_EXTS=('.com' '.co.uk' '.net' '.info' '.mobi')
        DOMAIN_EXTS+=('.org' '.tel' '.biz' '.tv' '.cc' '.eu' '.ru')
        DOMAIN_EXTS+=('.in' '.it' '.sk' '.com.au')
    else
        CHECK_DOMAIN="1"
    fi

    # -- Check if domain is available
    WHOIS_OUT=$(whois $DOMAIN)
    if [[ $CHECK_DOMAIN == "1" ]]; then
        echo "Checking single domain $DOMAIN"
        WHOIS_DOMAIN=$(echo $WHOIS_OUT | egrep -q '^No match|^NOT FOUND|^Not fo|AVAILABLE|^No Data Fou|has not been regi|No entri')        
        if [[ $? -eq 0 ]]; then
            echo -e "${DOMAIN}: $bg[green] > Available to Register  < ${RSC}"            
        else 
            echo "Registration Status : $bg[red]X Registered X ${RSC}"
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