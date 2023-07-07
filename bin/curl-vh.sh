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
-port       Port to resolve DNS, defaults to 44
-ip         IP of server, defaults to 127.0.0.1
-ssl        will disply SSL certficate information.
-v          Displays curl verbose
-f          Follows location, aka redirects
-c          Don't show just headers, show content
-d          Debug
Example: ./curl-vh -ip 127.0.0.1 -port 443 -ssl https://google.com
"
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
zparseopts -D -E ip:=O_IP port:=O_PORT ssl=O_SSL v=O_VERBOSE f=O_FOLLOW c=O_CONTENT d=O_DEBUG

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
    do_curl
fi