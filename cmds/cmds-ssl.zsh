# --
# ssl commands
#
# Example help: help_ssl[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_ssl

# -- ssl-check
help_ssl[ssl-check]='Check SSL Certificate on host'
ssl-check () { 
	if [[ ! $1 ]]; then
		echo "usage: ssl-check <hostname>"
	else
		echo "-- Checking SSL Certificate on $1"
		output=$(echo | openssl s_client -showcerts -servername $1 -connect $1:443 2>/dev/null | openssl x509 -inform pem -noout -text)
		echo $output
		echo "---------------------------------------------------"
		echo ""
		echo " -- Grabbing Validity"
		echo $output | grep -A2 'Validity'
		echo " -- Grabbing Subject: CN"
		echo $output | grep 'Subject: CN'
	fi
}