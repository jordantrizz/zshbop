# --
# curl commands
#
# Example help: help_curl[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_openssl

# -- curl-vh
help_curl[checkcert]="Check .pem file for certificate"
checkcert () { 
	if [[ -z $1 ]]; then
		echo "Usage: ./$0 <certificate.pem>"
		return 1
	fi
	openssl x509 -in $1 -text -noout
}

