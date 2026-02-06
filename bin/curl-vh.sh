#!/bin/zsh

# ------------
# -- Variables
# ------------
source $ZBR/lib/include.zsh

# ------------
# -- Functions
# ------------

# -- url_to_domain
url_to_domain () {
	_debug "\$1 = ${1}"
	DOMAIN=$(echo "${1}" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
}

# -- usage
usage () {
        echo "\
Usage: ./$0 [-ip 127.0.0.1|-port 443|-ssl] <url>
-h, --help      Show this help message
-port           Port to resolve DNS, defaults to 443
-ip             IP of server, defaults to 127.0.0.1
-ssl            will disply SSL certficate information.
--show-ssl          Print SSL/TLS version, cert issuer, CNs, and response headers
--show-ssl-verbose  Print full SSL certificate and connection data
-v                  Displays curl verbose
-f              Follows location, aka redirects
-c              Don't show just headers, show content
-d              Debug
Example: ./curl-vh -ip 127.0.0.1 -port 443 -ssl https://google.com
"
}

# -- do_show_ssl
do_show_ssl () {
    _loading "Checking SSL/TLS version for ${DOMAIN}:${PORT} via ${SERVERIP}"
    CURL_FULL=$(curl --head --resolve ${DOMAIN}:${PORT}:${SERVERIP} ${URL} -k -vvv 2>&1)

    # -- Show SSL/TLS version
    SHOW_SSL_OUTPUT=$(echo "$CURL_FULL" | grep 'SSL connection using')
    if [[ -n $SHOW_SSL_OUTPUT ]]; then
        _success "$SHOW_SSL_OUTPUT"
    else
        _warning "Could not determine SSL/TLS version"
    fi

    # -- Show certificate issuer and subject CNs
    _loading "Certificate details via openssl"
    CERT_INFO=$(openssl s_client -connect ${DOMAIN}:${PORT} -servername ${DOMAIN} </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -ext subjectAltName 2>/dev/null)
    if [[ -n $CERT_INFO ]]; then
        echo "$CERT_INFO" | while IFS= read -r line; do
            _success "$line"
        done
    else
        _warning "Could not retrieve certificate details"
    fi

    # -- Show response headers
    _loading "Response headers"
    echo "$CURL_FULL" | grep -E '^< ' | sed 's/^< //'
}

# -- do_show_ssl_verbose
do_show_ssl_verbose () {
    _loading "Full SSL/TLS data for ${DOMAIN}:${PORT} via ${SERVERIP}"

    # -- Full verbose curl SSL output
    _loading "Curl SSL connection details"
    curl --head --resolve ${DOMAIN}:${PORT}:${SERVERIP} ${URL} -k -vvv 2>&1 | grep -E '^\*' | sed 's/^\* //'

    # -- Full certificate details via openssl
    _loading "Full certificate data via openssl"
    openssl s_client -connect ${DOMAIN}:${PORT} -servername ${DOMAIN} </dev/null 2>/dev/null | openssl x509 -noout -text 2>/dev/null

    # -- Certificate chain
    _loading "Certificate chain"
    openssl s_client -connect ${DOMAIN}:${PORT} -servername ${DOMAIN} -showcerts </dev/null 2>/dev/null | grep -E 's:|i:'
}

# -- do_curl
do_curl (){
    _loading2 "Running: curl --resolve ${DOMAIN}:${PORT}:${SERVERIP} ${URL} ${EXTRA_ARGS} -k 2>&1"

    if [[ -n $O_SSL ]]; then
        _loading "Getting SSL certificate information from curl"            
        CURL_CMD="curl --head -vvv --resolve ${DOMAIN}:${PORT}:${SERVERIP} ${URL} -k --cert-status 2>&1 | grep -A10 'SSL connection'"
        _loading3 "Running - $CURL_CMD"
        eval $CURL_CMD

        _loading "Getting SSL certificate information from openssl"
        openssl s_client -connect $DOMAIN:443 </dev/null 2>/dev/null | openssl x509 -noout -text | grep DNS:
    else
        eval "curl --head --resolve ${DOMAIN}:${PORT}:${SERVERIP} ${URL} ${EXTRA_ARGS} -k 2>&1"
    fi
}

ALLARGS="$@"
# -- Gather options
zparseopts -D -E h=O_HELP -help=O_HELP ip:=O_IP port:=O_PORT ssl=O_SSL -show-ssl=O_SHOW_SSL -show-ssl-verbose=O_SHOW_SSL_VERBOSE v=O_VERBOSE f=O_FOLLOW c=O_CONTENT d=O_DEBUG

# -- Help
if [[ -n $O_HELP ]]; then
    usage
    exit 0
fi

# -- Debug
if [[ -n $O_DEBUG ]]; then
    DEBUGF="1"
    _success "Debug enabled"
fi

# -- IP
_debugf "\$O_IP = $O_IP"
if [[ -z $O_IP ]]; then
	_debugf "No IP provided using 127.0.0.1"
	SERVERIP="127.0.0.1"
elif [[ $O_IP == "" ]]; then
	usage
	_error "-ip specified but no IP provided"
else
	SERVERIP="$O_IP[2]"
fi

# -- Port
_debugf "\$O_PORT = $O_PORT"
if [[ -z $O_PORT ]]; then
    PORT="443"
else
	PORT=$O_PORT[2]
	_debug "PORT = $PORT was $O_PORT"
fi

# -- SSL
[[ -n $O_SSL ]] && SSL="1"

# -- Verbose
if [[ -n $O_VERBOSE ]]; then
	EXTRA_ARGS=" -vvv"
	VERBOSE="1"
elif [[ -n $O_SSL ]]; then
    EXTRA_ARGS=" -vvv"    
fi


# -- Follow
if [[ -n $O_FOLLOW ]]; then
	EXTRA_ARGS+=" -l"
fi

# -- Content
if [[ -z $O_CONTENT ]]; then
	EXTRA_ARGS+=" --head"
fi

# ------------
# -- Main Loop
# ------------
if [[ -z $1 ]]; then
	usage
    _error "Missing domain argument"
    exit 1
else
    _debug "\$@ = $@"
    URL="$1"
    url_to_domain ${1}
    _debug "vars - \$URL=$URL \$DOMAIN=$DOMAIN \$SERVERIP=$SERVERIP \$PORT=$PORT \$SSL=$SSL \$VERBOSE=$VERBOSE \$EXTRA_ARGS=$EXTRA_ARGS \$GREP_ARGS=$GREP_ARGS"
    if [[ -n $O_SHOW_SSL_VERBOSE ]]; then
        do_show_ssl_verbose
    elif [[ -n $O_SHOW_SSL ]]; then
        do_show_ssl
    else
        do_curl
    fi
fi