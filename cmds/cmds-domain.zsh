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
help_files[domain_description]="Domain Name functions and commands."
help_files[domain]="Domain Name functions and commands."

# -- domaincheck
help_domain[domaincheck]='Check if a domain name is available'
alias domaincheck="domaincheck.sh"

# -- domain-info
help_domain[domain-info]='Check a domains name servers and www and a record and print them out'
domain-info () {
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
    if [ $# -eq 0 ]; then
        echo "Usage: domain-info <domain_name>"
        return 1
    fi

    DOMAIN=$1

    # Check if domain is using Cloudflare nameservers
	_loading2 "Checking if $DOMAIN nameservers"
    NAMESERVERS=$(dig +short NS $DOMAIN)
    
    echo ""
    IS_CF=0
    if echo $NAMESERVERS | grep -Eq "([a-z]+\.ns\.cloudflare\.com)"; then
        IS_CF=1
        echo "$bg[yellow]$fg[black]Cloudflare Nameservers${reset_color}"
    else
		echo "Nameservers for $DOMAIN:"
    fi
    
    echo "-------------"   
    echo "$NAMESERVERS"
    echo "-------------"
    echo ""

    # Check apex record
	if [[ $IS_CF == 1 ]]; then	
	    _loading2 "Checking if $DOMAIN apex is proxied."
	    APEX_RECORD=$(dig +short A $DOMAIN)
	    echo "Apex record for $DOMAIN:"
	    for IP in "${(f)APEX_RECORD}"; do
		   	if [[ $(grepcidr3 -D "$IP" <(echo "$CLOUDFLARE_IPS")) ]]; then
	    		echo "$IP is $bg[yellow]$fg[black]CF proxied.${reset_color}"
	        else
	        	echo "$IP is not CF proxed"
	        fi
		done
		echo ""

    	_loading2 "Checking if $DOMAIN www is proxied."
    	WWW_RECORD=$(dig +short A www.$DOMAIN)
    	echo "WWW record for $DOMAIN:"
    	for IP in "${(f)WWW_RECORD}"; do
            if [[ $(grepcidr3 -D "$IP" <(echo "$CLOUDFLARE_IPS")) ]]; then
                echo "$IP is $bg[yellow]$fg[black]CF proxied.${reset_color}"
            else
                echo "$IP is not CF proxed"
            fi
        done
	fi
}
