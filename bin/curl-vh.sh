#!/bin/zsh

# ------------
# -- Variables
# ------------
VERSION=0.0.1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DEBUG="0"

# -- Colors
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
BLUEBG="\e[44m"
YELLOWBG="\e[43m"
GREENBG="\e[42m"
DARKGREYBG="\e[100m"
ECOL="\e[0m"

# ------------
# -- Functions
# ------------

# -- _error
_error () {
    echo -e "${RED}** ERROR ** - $@ ${ECOL}"
}

_success () {
    echo -e "${GREEN}** SUCCESS ** - $@ ${ECOL}"
}

_running () {
    echo -e "${BLUEBG}${@}${ECOL}"
}

_creating () {
    echo -e "${DARKGREYBG}${@}${ECOL}"
}

_separator () {
    echo -e "${YELLOWBG}****************${ECOL}"
}

_debug () {
    if [[ $DEBUG == "1" ]]; then
        echo -e "${CYAN}** DEBUG: $@${ECOL}"
    fi
}

url_to_domain () {
	echo "${1}" | sed -e 's|^[^/]*//||' -e 's|/.*$||'
}

usage () {
        echo "Usage: ./$0 [-ip=|-port=|-ssl] <url>"
        echo "  -port       Port to resolve DNS, defaults to 44"
        echo "  -ip         IP of server, defaults to 127.0.0.1"
        echo "  -ssl        will disply SSL certficate information."
        echo "  -v          Displays curl verbose"
        echo "  -f          Follows location, aka redirects"
        echo "  -c          Don't show just headers, show content"
        echo "  -d          Debug"
        echo ""
}

do_curl (){
    _running "Running: curl --resolve ${DOMAIN}:${PORT}:${SERVERIP} ${URL} ${EXTRA_ARGS} -k 2>&1 ${GREP_ARGS}"
	echo ""
	eval "curl --resolve \"${URL}:${PORT}:${SERVERIP}\" ${URL} ${EXTRA_ARGS} -k 2>&1 ${GREP_ARGS}"
}

# -- Gather options
zparseopts -D -E ip:=O_IP p:=O_PORT ssl=O_SSL v=O_VERBOSE f=O_FOLLOW c=O_CONTENT d=O_DEBUG

echo $O_DEBUG

# -- Clear Variables
IP=""
PORT=""
GREP_ARGS=""
EXTRA_ARGS=""

# -- IP
if [[ -z $O_IP ]]; then
	_debug "No IP provided using 127.0.0.1"
	SERVERIP="127.0.0.1"
elif [[ $O_IP == "" ]]; then
	usage
	_error "-ip specified but no IP provided"
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

# -- Debug
if [[ -n $O_DEBUG ]]; then  
    DEBUG="1"
    _success "Debug enabled"
fi

if [[ -z $1 ]]; then
	usage
    _error "Missing domain argument"
    exit 1
else
    URL="$1"
    DOMAIN=$(url_to_domain $1)
    _debug "vars - \$URL=$URL \$DOMAIN=$DOMAIN \$SERVERIP=$SERVERIP \$PORT=$PORT \$SSL=$SSL \$VERBOSE=$VERBOSE \$EXTRA_ARGS=$EXTRA_ARGS \$GREP_ARGS=$GREP_ARGS"	
    do_curl
fi


