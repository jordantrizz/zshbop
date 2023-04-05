#!/bin/bash

# ==================================
# -- Variables
# ==================================
VERSION=0.1.0
SCRIPT_NAME=betteruptime-cli
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
API_URL="https://betteruptime.com/api/v2"
DEBUG="0"
REQUIRED_APPS=("jq" "column")

# -- Colors
export NC='\e[0m' # No Color
export CBLACK='\e[0;30m'
export CGRAY='\e[1;30m'
export CRED='\e[0;31m'
export CLIGHT_RED='\e[1;31m'
export CGREEN='\e[0;32m'
export CLIGHT_GREEN='\e[1;32m'
export CBROWN='\e[0;33m'
export CYELLOW='\e[1;33m'
export CBLUE='\e[0;34m'
export CLIGHT_BLUE='\e[1;34m'
export CPURPLE='\e[0;35m'
export CLIGHT_PURPLE='\e[1;35m'
export CCYAN='\e[0;36m'
export CLIGHT_CYAN='\e[1;36m'
export CLIGHT_GRAY='\e[0;37m'
export CWHITE='\e[1;37m'

# ==================================
# -- Usage
# ==================================
USAGE_FOOTER=\
"Version: $VERSION
Type $SCRIPT_NAME help for more."

USAGE=\
"$SCRIPT_NAME [-a <apikey>|-d] <command>

Commands:
	test                - Test Better Uptime API key.
	list <monitor>      - List objects
	create               - Create object
    search <string>      - Search for <string>

Options:
    -a               - Better Uptime apikey team (Optional)
    -d               - Debug mode (Optional)
    -j               - Debug json mode, print out json

API Key:
    The Better Uptime API Credentials should be placed in \$HOME/.cloudflare
    Since there is a separate API key for teams, you can set a default and set
    a team API key. The format as follows.

	Default API Key:  BETTER_UPTIME_APIKEY=\"\"
	Team API Key:     TEAM_BETTER_UPTIME_APIKEY=\"\"
    
    Replace TEAM with your placeholder and pass \"-a TEAM\" option. If -a isn't
    set then the default BETTER_UPTIME_APIKEY is used.

${USAGE_FOOTER}
"

USAGE_LIST=\
"$SCRIPT_NAME [-a <apikey>|-d] list <object>

Objects:
	monitors         - Create monitor.
	heartbeat        - Create Heartbeat.

${USAGE_FOOTER}
"

# ==================================
# -- Core Functions
# ==================================

# -- messages
_error () { echo -e "${CRED}** ERROR ** - ${*} ${NC}"; } # _error
_success () { echo -e "${CGREEN}** SUCCESS ** - ${*} ${NC}"; } # _success
_running () { echo -e "${BLUEBG}${*}${NC}"; } # _running
_creating () { echo -e "${DARKGREYBG}${*}${NC}"; }
_separator () { echo -e "${YELLOWBG}****************${NC}"; }
_debug () {
    if [[ $DEBUG == "1" ]]; then
        echo -e "${CCYAN}** DEBUG ${*}${NC}"
    fi
}

# -- debug_jsons
_debug_json () {
    if [[ $DEBUG_JSON == "1" ]]; then
        echo -e "${CCYAN}** Outputting JSON ${*}${NC}"
        echo "${@}" | jq
    fi
}

# -- usage
usage () {
	if [[ -z $1 ]]; then
	    echo "$USAGE"
	else
		USAGE_TEXT="USAGE_${1}"
		echo "${!USAGE_TEXT}"
	fi
}

# ==================================
# -- Functions
# ==================================

# -- pre_flight_check
function pre_flight_check () {
	# -- Check for better uptime api key in file or shell variable
    _debug "Checking for Better Uptime API Key"
    if [[ -f ~/.betteruptime ]]; then
		_debug "Found $HOME/.betteruptime"
	    source "$HOME/.betteruptime"
	else
		if [[ -z $BETTER_UPTIME_APIKEY ]]; then
            usage
	        _error "Can't find $HOME/.betteruptime or \$BETTER_UPTIME_APIKEY in shell...exiting."	    
	        exit 1
        fi
	fi

    # -- Check if $REQUIRED_APPS are installed
    for CMD in "${REQUIRED_APPS[@]}"; do
        if ! command -v "$CMD" &> /dev/null; then
        _error "$CMD is not installed"
        fi
    done

}

# -- bu_api <$API_PATH> <$REQUEST>
function bu_api() {
	_debug "Running bu_api() with ${*}"
	local $API_PATH	$REQUEST
	API_PATH="$1"    
    CURL_OUTPUT=$(mktemp)
	
    _debug "Running curl -s --request $REQUEST --url "${API_URL}${API_PATH}" --header 'Authorization: Bearer '"${BETTER_UPTIME_APIKEY}"''"
    CURL_EXIT_CODE=$(curl -s -w "%{http_code}" --request GET\
	    --request GET \
	    --url "${API_URL}${API_PATH}" \
	    --header "Authorization: Bearer ${BETTER_UPTIME_APIKEY}" \
	    --output "$CURL_OUTPUT")    
    API_OUTPUT=$(<"$CURL_OUTPUT")
    _debug_json "$API_OUTPUT"
    rm $CURL_OUTPUT    

		
	if [[ $CURL_EXIT_CODE == "200" ]]; then
	    _debug "Success from API: $CURL_EXIT_CODE"	     
	else
        _error "Error from API: $API_OUTPUT"
        exit 1
    fi
}

# -- bu_api_test
function bu_api_test() {	
    _debug "function:${FUNCNAME[0]}"
	bu_api /monitors GET		
	if [[ $? -ge "1" ]]; then
        _error "Better Uptime API connection not working!"
        exit 1
	else
		_success "Better Uptime API connection working!"
		exit 0
	fi
}

# -- bu_list_monitors
function bu_list_monitors () {
    if [[ $JSON_OUTPUT == "1" ]]; then
        echo $OUTPUT
        exit
    else
        _running "Listing monitors"
        _debug "Outputting clean"
        PARSED_OUTPUT=$(echo $API_OUTPUT | jq -r '(["ID","MONITOR_TYPE","URL","PRONAME","GROUP","STATUS"] |
            (., map(length*"-"))),
            (.data[] | [ .id,
            .attributes["monitor_type"],
            .attributes["url"],
            .attributes["pronounceable_name"],
            .attributes["monitor_group_id"],
            .attributes["status"]
            ])|join(",")' | column -t -s ',')
        HEADER_OUTPUT=$(printf "$PARSED_OUTPUT" | awk 'FNR <= 2')
        printf "$PARSED_OUTPUT" | awk -v h="$HEADER_OUTPUT" '{print}; NR % 10 == 0 {print "\n" h}'
        exit
    fi
}

# -- bu_create_monitor # TODO need to do this ;)
function bu_crate_monitors () {
    _running "Create monitor"    
    
}

# -- bu_search
function bu_search () {
    _debug "function:${FUNCNAME[0]} $@"
    bu_api /monitors GET | jq '.data[] | select(.attributes.url | contains("$STRING")) | {id: .id, type: .type}'
	
#    echo $BU_SEARCH_RESULTS
}

# ==================================
# -- Arguments
# ==================================

# -- check if parameters are set
_debug "PARAMS: ${*}"
if [[ -z ${*} ]];then
	usage
	exit 1
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -a|--apikey)
    API_KEY_TEAM="$2"
    _debug "\$API_KEY_TEAM: $API_KEY_TEAM"
    shift # past argument
    shift # past value
    ;;
    -d|--debug)
    DEBUG="1"
    _debug "DEBUG enabled!"
    shift # past argument
    ;;
    -j|--json)
    JSON_OUTPUT="1"
    _debug "\$JSON_OUTPUT: $JSON_OUTPUT"
    shift # past argument
    ;;
    -dj|--debug-json)
    DEBUG_JSON="1"
    _debug "DEBUG_JSON enabled!"
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# ==================================
# -- Main Loop
# ==================================

# -- check better uptime credentials
pre_flight_check

# -- Loop
CMD1=$1
_debug "\$CMD1:$CMD1"
shift
    case "$CMD1" in
        #### usage
        help)
		    usage
		    exit
        ;;

		#### test
        test)
            bu_api_test
		;;
		
        #### list
        list)
        CMD2=$1
        _debug "\$CMD2:$CMD2"
        shift
            case "$CMD2" in
                # -- monitors
                monitors)
					bu_api /monitors GET
                    bu_list_monitors
                ;;
                heartbeats)
                    echo "heartbeats"
                    exit
        		;;
        		*)
                    usage LIST
                    exit 1
        	esac
        ;;
        #### search
        search)
            if [[ -z ${1} ]]; then
                _error "Please provide a string: search <string>"
            else
                _debug "Searching for ${1}"
                bu_search ${1}
            fi
        ;;
		#### add
        add)
		    if [[ -z ${1} ]]; then
                _error "Please provide a string: search <string>"
            else
                _debug "Searching for ${1}"
                bu_search ${1}
            fi
        ;;

		#### catchall
        *)
        usage
        _error "No command specified"
        exit 1
        ;;
esac