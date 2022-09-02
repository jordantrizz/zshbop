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
    # -- Gather options
    zparseopts -D -E ip:=O_IP p:=O_PORT ssl=O_SSL v=O_VERBOSE f=O_FOLLOW c=O_CONTENT

	# -- Clear Variables
	IP=""
	PORT=""
    GREP_ARGS=""
    EXTRA_ARGS=""
    
    # -- IP
    if [[ -z $C_IP ]]; then
        SERVERIP="127.0.0.1"
    else
    	SERVERIP=$O_IP[2]
    fi

    # -- Port
    if [[ -z $O_PORT ]]; then
        PORT="443"
    else
    	PORT=$O_PORT[2]
    fi

	# -- SSL
    if [[ -n $O_SSL ]]; then
        GREP_ARGS="| grep -A10 'SSL connection'"
        EXTRA_ARGS=" -vvv"
        SSL="1"
    fi

    # -- Verbose
    if [[ -n $O_VERBOSE ]]; then
    	EXTRA_ARGS=" -vvv"
    	VERBOSE="1"
    fi
    
    # -- Follow
    if [[ -n $O_FOLLOW ]]; then
    	EXTRA_ARGS+=" -l"
    fi
    
    # -- Content
    if [[ -z $O_CONTENT ]]; then
    	EXTRA_ARGS+=" --head"
    fi    

	_debug "vars - \$SERVERIP=$SERVERIP \$PORT=$PORT \$SSL=$SSL \$VERBOSE=$VERBOSE \$EXTRA_ARGS=$EXTRA_ARGS \$GREP_ARGS=$GREP_ARGS"
	
	if [[ -z $1 ]]; then
		echo "Usage: ./$0 [-ip=|-port=|-ssl] <domain>"
		echo "  -port       Port to resolve DNS, defaults to 44"
		echo "  -ip         IP of server, defaults to 127.0.0.1"
		echo "  -ssl        will disply SSL certficate information."
		echo "  -v          Displays curl verbose"
		echo "  -f          Follows location, aka redirects"
		echo "  -c          Don't show just headers, show content"
		echo ""
		return 1
	fi
	DOMAIN=$1
	_loading "Running: curl --resolve ${DOMAIN}:${PORT}:${SERVERIP} https://${DOMAIN} ${EXTRA_ARGS} -k 2>&1 ${GREP_ARGS}"
	echo ""
	eval "curl --resolve ${DOMAIN}:${PORT}:${SERVERIP} https://${DOMAIN} ${EXTRA_ARGS} -k 2>&1 ${GREP_ARGS}"
}

