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
	_cexists ttfb
	if [[ $? == "0" ]]; then
		echo "ttfb existing in your path, simply run ttfb"
		return
	else
		echo "ttfb not installed, run 'sudo install cargo;cargo install ttfb'"
	fi
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

# -- web-toprequests
help_gridpane[web-toprequests]="Get the top requests in an access log"
web-toprequests_usage () {
    echo "Usage: web-toprequests <ols|nginx|rcols> <log> (lines)"
    echo ""
    echo "  ols = Default OLS"
    echo "  nginx = "Default Nginx
    echo "  rcols = Runcloud OLS"
    echo "  gpnginx = GridPane Nginx"
    echo "  gpols = GridPane OLS"
}

web-toprequests () {
	if [[ -z "$1" ]] && [[ -z "$2" ]]; then
		web-toprequests_usage
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
        
        if [[ $1 == "ols" ]]; then
            _error "Not working"
            return 1
        elif [[ $1 == "nginx" ]]; then
            _error "Not working"
            return 1
		elif [[ $1 == "gpols" ]]; then
            cat ${2} | awk {' print $6 " - " $9 " - " $7 '} | sort -nr | uniq -c | sort -nrk1 |head ${SETLINES}
        elif [[ $1 == "gpnginx" ]]; then
            cat ${2} | awk {' print $7 " - " $10 " - " $8 '} | sort -nr | uniq -c | sort -nrk1 | head ${SETLINES}
        elif [[ $1 == "rcols" ]]; then
            # "domain.com 127.0.0.1 - - [24/Mar/2023:14:47:33 +0000] "POST /wp-admin/admin-ajax.php?_fs_blog_admin=true HTTP/2" 200 36"
            cat ${2} | awk {' print $7 " - " $10 " - " $8 '} | sort -nr | uniq -c | sort -nrk1 | head ${SETLINES}
        else
           web-toprequests_usage
           _error "Unknown $@"
        fi
	fi
}