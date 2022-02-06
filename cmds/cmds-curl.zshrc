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
help_curl[curl-vh]='Curl and set virtual host.'
curl-vh () { 
	if [[ ! $1 ]] && [[ ! $2 ]]; then
		echo "usage: ./vh_run <ip> <hostname>"
	else
		echo " -- Running curl on $1 with hostname $2"
		#vh_run=$(curl --header "Host: $2" $1 --insecure -i | head -50)
		curl --header "Host: $2" $1 --insecure -i
		#echo $vh_run 
	fi
}