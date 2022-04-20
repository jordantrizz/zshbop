# --
# curl commands
#
# Example help: help_curl[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_curl

# -- curl-vh
help_curl[curl-vh]='Curl an ip address and set host header.'
curl-vh () { 
	if [[ ! $1 ]] && [[ ! $2 ]] && [[ ! $3 ]] && [[ ! $4 ]]; then
		echo "usage: ./$0 <URL> <domain> <port> <serverip>"
	else
		#vh_run=$(curl --header "Host: $2" $1 --insecure -i | head -50)
		#curl --header "Host: $2" $1 --insecure -i
		#echo $vh_run 
		url=$1
		domain=$2
		port=$3
		serverip=$4
		echo " -- Running -- curl --head $url --resolve '$domain:$port:$serverip'"
		curl --head $url --resolve "'$domain:$port:$serverip'"
	fi
}