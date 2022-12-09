#!/bin/bash

# ------------
# -- Variables
# ------------
VERSION=0.0.1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DEBUG="0"
DATE=`date +"%Y-%m-%d %T"`
DATE=`date +"%Y-%m-%d-%H_%M_%S"`

# -- Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
BLUEBG="\033[0;44m"
YELLOWBG="\033[0;43m"
GREENBG="\033[0;42m"
DARKGREYBG="\033[0;100m"
ECOL="\033[0;0m"

# -------
# -- Help
# -------
USAGE=\
"$0 <command>

Betteruptime API Credentials should be placed in \$HOME/.cloudflare
  BU_KEY=\"\"

Version: $VERSION
"

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
    if [ -f $SCRIPT_DIR/.debug ]; then
        echo -e "${CYAN}** DEBUG: $@${ECOL}"
    fi
}

_debug () {
    if [[ $DEBUG == "1" ]]; then
        echo -e "${CYAN}** DEBUG: $@${ECOL}"
    fi
}

usage () {
    echo "$USAGE"
}

# -- betteruptime-api <$API_PATH>
betteruptime-api() {
	local $API_PATH	
	API_PATH=$1

	CURL_OUTPUT=$(curl -s --request GET \
		 --url https://betteruptime.com/${API_PATH} \
  	     --header 'Authorization: Bearer "'${BU-KEY}'"')
  	_debug "$CURL_OUTPUT" 	     
	CURL_OUTPUT_JQ=$(echo $CURL_OUTPUT | jq -r)
    return $CURL_OUTPUT_JQ  	
}

# -- betteruptime-api-creds
betteruptime-api-creds() {
	if [[ -f ~/.betteruptime ]]; then
		_debug "Found $HOME/.betteruptime"
	    source $HOME/.betteruptime
	else
		usage
	    _error "Can't find $HOME/.cloudflare exiting."	    
	    exit 1
	fi
}

# -- betteruptime-api-test
betteruptime-api-test() {
	betteruptime-api
}

# ------------
# -- Main loop
# ------------

betteruptime-api-creds
betteruptime-api-test


if [[ -z $1 ]];then
	usage
else
	echo "Nothing here yet"
fi