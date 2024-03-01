# --
# Core commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[web]='Web commands'

# - Init help array
typeset -gA help_web

_debug " -- Loading ${(%):-%N}"


# -- paths
help_web[ttfb-rust]='Find out TTFB for a website. Rust app requires cargo from https://github.com/phip1611/ttfb updated frequently'
ttfb-rust () {
	_cmd_exists ttfb
    [[ $? == "0" ]] && echo "ttfb existing in your path, simply run ttfb" || echo "ttfb not installed, run 'sudo install cargo;cargo install ttfb'"
}

# -- curl-ttfb
help_web[curl-ttfb]='Curl to get TTFB or Time To First Byte. Random code from the interwebs.'
curl-ttfb () {
        curl -s -o /dev/null -w "Connect: %{time_connect} TTFB: %{time_starttransfer} Total time: %{time_total} \n" $1
}

# -- curl-ttfb2
help_web[curl-ttfb2]='Curl to get TTFB or Time To First Byte from https://github.com/jaygooby/ttfb.sh updated 2021. Allows for multiple requests.'
alias curl-ttfb2="ttfb2"

# -- image-opt
help_web[image-opt]="Optimize images"

# -- web-topips
help_web[web-topips]="Get the top requests by IP in an OLS or Nginx access log"
web-topips_usage () {
    echo "Usage: web-topips <ols|nginx|rcols> <log> (lines)"
    echo "    rcols = Runcloud OLS"
}

web-topips () {
	if [[ -z "$1" ]] && [[ -z "$2" ]]; then
		web-topips_usage
        _error "Unknown $@"
        return 1
	else
        TYPE="$1"
        LOG="$2"
        LINES="$3"

        # Set lines
        [[ ${LINES} ]] && SETLINES="-${LINES}" || SETLINES=""
        
        # - Check if log exists        
        [[ ! -f $LOG ]] && { _error "Couldn't find log: $LOG"; return 1; }

        # - Process
		if [[ $1 == "ols" ]]; then
            cat ${LOG} | awk {' print $1 '} | uniq -c | sort -nr | head ${SETLINES}
        elif [[ $1 == "nginx" ]]; then
            cat ${LOG} | awk {' print $3 '} | uniq -c | sort -nr | head ${SETLINES}
        elif [[ $1 == "rcols" ]]; then
            cat ${LOG} | awk {' print $2 '} | uniq -c | sort -nr | head ${SETLINES}
        else
            _error "Unknown $@"
        fi
	fi
}



help_web[php-opcode]="Look for php.ini opcode settings in /etc/php"
function php-opcode() {
    if [[ -z $1 ]]; then
        echo "Usage: ${funcstack[1]} <all|phpver>"
        echo "   phpver = php80 or php73"
        return 1
    else
        _loading "Looking for opcache settings in php.ini files located in /etc/php"
        if [[ $1 == 'all' ]]; then
            find /etc/php -name php.ini -type f -print0 | while IFS= read -r -d '' ini_file; do
                _loading2 "==== $ini_file ===="
                grep opcache "$ini_file" | egrep -v ';|^$'
            done
        else
            _loading "Looking for opcache settings in php.ini for ${1}"
            files=($(find /etc/php -name php.ini -type f | grep "${1}"))
            for ini_file in ${files[@]}; do
                _loading2 "==== $ini_file ===="
                grep opcache "$ini_file" | egrep -v ';|^$'
            done
        fi
    fi
}

# -- http-status-codes
help_web[http-status-codes]="Print out a list of http error codes"
function http-status-codes() {
    declare -A HTTTP_STATUS_CODES
    HTTTP_STATUS_CODES=(
        [100]="Continue"
        [101]="Switching Protocols"
        [102]="Processing"
        [103]="Early Hints"
        [200]="OK"
        [201]="Created"
        [202]="Accepted"
        [203]="Non-Authoritative Information"
        [204]="No Content"
        [205]="Reset Content"
        [206]="Partial Content"
        [207]="Multi-Status"
        [208]="Already Reported"
        [226]="IM Used"
        [300]="Multiple Choices"
        [301]="Moved Permanently"
        [302]="Found"
        [303]="See Other"
        [304]="Not Modified"
        [305]="Use Proxy"
        [306]="Switch Proxy"
        [307]="Temporary Redirect"
        [308]="Permanent Redirect"
        [400]="Bad Request"
        [401]="Unauthorized"
        [402]="Payment Required"
        [403]="Forbidden"
        [404]="Not Found"
        [405]="Method Not Allowed"
        [406]="Not Acceptable"
        [407]="Proxy Authentication Required"
        [408]="Request Timeout"
        [409]="Conflict"
        [410]="Gone"
        [411]="Length Required"
        [412]="Precondition Failed"
        [413]="Payload Too Large"
        [414]="URI Too Long"
        [415]="Unsupported Media Type"
        [416]="Range Not Satisfiable"
        [417]="Expectation Failed"
        [418]="I'm a teapot"
        [421]="Misdirected Request"
        [422]="Unprocessable Entity"
        [423]="Locked"
        [424]="Failed Dependency"
        [425]="Too Early"
        [426]="Upgrade Required"
        [428]="Precondition Required"
        [429]="Too Many Requests"
        [431]="Request Header Fields Too Large"
        [451]="Unavailable For Legal Reasons"
        [500]="Internal Server Error"
        [501]="Not Implemented"
        [502]="Bad Gateway"
        [503]="Service Unavailable"
        [504]="Gateway Timeout"
        [505]="HTTP Version Not Supported"
        [506]="Variant Also Negotiates"
        [507]="Insufficient Storage"
        [508]="Loop Detected"
        [510]="Not Extended"
        [511]="Network Authentication Required"
        [520]="Cloudflare - Unknown Error"
        [521]="Cloudflare - Web Server Is Down"
        [522]="Cloudflare - Connection timed out"
        [523]="Cloudflare - Origin Is Unreachable"
        [524]="Cloudflare - A timeout occurred"
        [525]="Cloudflare - SSL handshake failed"
        [526]="Cloudflare - Invalid SSL certificate"
        [527]="Cloudflare - Railgun Error"
        [530]="Cloudflare - Check 1xx Error"
        [1000]="Cloudflare - DNS points to prohibited IP"
        [1001]="DNS resolution error"
    )

    function _http_status_codes_usage () {
        echo ""
        echo "Usage: http-status-codes [code]"
        echo "You can search for a specific code by passing it as an argument"
    }
    
    function _httpd_status_codes_print () {
        _loading "Listing all http error codes:"
        echo ""
        for code in "${(@ok)HTTTP_STATUS_CODES[@]}"; do
            echo "$code - ${HTTTP_STATUS_CODES[$code]}"            
        done        
        _http_status_codes_usage
    }

    _httpd_status_codes_search () {
        local SEARCH_CODE=$1
        _loading "Searching for $SEARCH_CODE"
        echo ""
        for code in "${(@ok)HTTTP_STATUS_CODES}"; do
            if [[ $code == *"$SEARCH_CODE"* ]]; then
                echo "$code - ${HTTTP_STATUS_CODES[$code]}"
            fi
        done        
        _http_status_codes_usage
    }
    
    if [[ $# -eq 0 ]]; then
        _httpd_status_codes_print
    elif [[ $# -eq 1 && ${HTTTP_ERROR_CODES[$1]} ]]; then
        code=$1
        echo "$code - ${HTTTP_ERROR_CODES[$code]}"
    # -- Check if theres a partial match ie 4 would print all 4xx codes
    else
        _httpd_status_codes_search $1    
    fi    
}

