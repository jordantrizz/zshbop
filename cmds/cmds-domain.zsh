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
domain () {
    USAGE=\
"Usage: domaincheck (domain.ext|-a domain)
   Check if a domain name is available. Enter in the full domain name
   -a    - check all domain extensions, just enter the first part
"
    DOMAIN="$1"

    if [[ -z $1 ]]; then
        echo $USAGE
        return 1
    fi

    _loading "Checking $DOMAIN"

    if [[ $1 == "-a" ]]; then
        echo " - Checking all domain extensions"
        CHECK_DOMAIN="2"
        DOMAIN_EXTS=( '.com' '.co.uk' '.net' '.info' '.mobi' \
        '.org' '.tel' '.biz' '.tv' '.cc' '.eu' '.ru' \
        '.in' '.it' '.sk' '.com.au' )
    else
        CHECK_DOMAIN="1"
    fi

    if [[ $CHECK_DOMAIN == "1" ]]; then
        echo "Checking single domain $DOMAIN"
        WHOIS_DOMAIN=$(whois $DOMAIN | egrep -q '^No match|^NOT FOUND|^Not fo|AVAILABLE|^No Data Fou|has not been regi|No entri')
        [[ $? -eq 0 ]] && echo -e "${DOMAIN}: $bg[green] > available < ${RSC}" || echo -e "$DOMAIN : $bg[red]X unavailable X ${RSC}"
          
        echo $WHOIS_DOMAIN
    elif [[ $CHECK_DOMAIN == "2" ]]; then
        echo "Checking name $2 on $DOMAIN_EXTS"
        ELEMENTS=${#DOMAIN_EXTS[@]}
        while (( "$#" )); do
            for (( i=1; i<=$ELEMENTS; i++ )); do
                WHOIS_DOMAIN=$(whois ${DOMAINS[${i}]} | egrep -q '^No match|^NOT FOUND|^Not fo|AVAILABLE|^No Data Fou|has not been regi|No entri')
                if [ $? -eq 0 ]; then
                    echo -e "$1${DOMAIN_EXTS[$i]} : ${GREEN} > available < ${NC}"
                else
                    echo -e "$1${DOMAIN_EXTS[$i]} : ${RED}X unavailable X ${NC}"
                fi                    
            done
        shift
        done
    fi
}