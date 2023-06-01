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
	if [[ -z $1 ]]; then
		echo "Usage: ssl-check [-h hostname|-f file]"
	elif [[ $1 == "-h" ]]; then
		_loading "-- Checking SSL Certificate on $2"
		output=$(echo | openssl s_client -showcerts -servername $2 -connect $2:443 2>/dev/null | openssl x509 -inform pem -noout -text)
		echo $output
		_loading2 "---------------------------------------------------"
		echo ""
		_loading " -- Grabbing Validity"
		echo $output | grep -A2 'Validity'
		_loading " -- Grabbing Subject: CN"
		echo $output | grep 'Subject: CN'
		echo $output | grep 'DNS'
	elif [[ $1 == "-f" ]]; then
		_loading "-- Checking SSL Certificate on $2"
		openssl x509 -in $2 -text -noout
	else 
		echo "Usage: ssl-check [-h hostname|-f file]"
	fi
}

# -- gen-ss-cert
help_ssl[gen-ss-cert]='Generate a self signed certificate'
gen-ssl-cert () {
	openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -keyout cert.key -out cert.crt
	openssl x509 -in cert.crt -out cert.pem
	openssl rsa -in cert.key -out key.pem
}

# -- curl-vh
help_ssl[curl-vh]='Curl with verbose headers and SSL checking'