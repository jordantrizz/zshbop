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

# -- get-site-llm
help_web[get-site-llm]='Check llm.txt/llms.txt endpoints and markdown negotiation support for a site'
get-site-llm () {
    local _usage='Usage: get-site-llm [-h|--help] <domain-or-url>'
    local ARG_HELP
    local zparseopts_error=0

    zparseopts -D -E h=ARG_HELP -help=ARG_HELP || zparseopts_error=$?

    if (( zparseopts_error )); then
        _error "Invalid options"
        echo "$_usage"
        return 1
    fi

    if (( ${#ARG_HELP} )); then
        echo "$_usage"
        echo "Checks for /llm.txt, /llms.txt, /.well-known/llm.txt, /.well-known/llms.txt"
        echo "Outputs first 20 lines of first successful LLM file response"
        echo "Checks markdown support via Accept: text/markdown and validates markdown header (#)"
        return 0
    fi

    if [[ -z "$1" ]]; then
        echo "$_usage"
        return 1
    fi

    _cmd_exists curl
    if [[ $? != 0 ]]; then
        _error "curl is required"
        return 1
    fi

    local raw_input="$1"
    local input_url="$raw_input"
    local input_no_scheme host_with_path host page_path
    local active_base=""
    local llm_found=0
    local md_supported=0
    local md_header_found=0
    local first_nonempty_line=""
    local status_code=""
    local content_type=""
    local markdown_tokens=""
    local content_signal=""
    local vary_header=""
    local base_url=""
    local llm_path=""
    local llm_url=""
    local markdown_url=""
    local curl_rc=0
    local claude_ua="Mozilla/5.0 (compatible; ClaudeBot/1.0; +https://www.anthropic.com/bot)"

    local -a candidate_paths
    local -a candidate_bases

    candidate_paths=(
        "/llm.txt"
        "/llms.txt"
        "/.well-known/llm.txt"
        "/.well-known/llms.txt"
    )

    local tmp_headers tmp_body
    tmp_headers=$(mktemp) || { _error "Unable to create temp file"; return 1; }
    tmp_body=$(mktemp) || { rm -f "$tmp_headers"; _error "Unable to create temp file"; return 1; }

    # Normalize input to host + optional page path
    [[ "$input_url" == *" "* ]] && input_url=${input_url%% *}
    if [[ "$input_url" != http://* && "$input_url" != https://* ]]; then
        input_url="https://$input_url"
    fi

    input_no_scheme=${input_url#http://}
    input_no_scheme=${input_no_scheme#https://}
    input_no_scheme=${input_no_scheme%%\?*}
    input_no_scheme=${input_no_scheme%%\#*}

    host_with_path="$input_no_scheme"
    host=${host_with_path%%/*}
    host=${host#www.}

    if [[ -z "$host" ]]; then
        _error "Could not parse host from input: $raw_input"
        rm -f "$tmp_headers" "$tmp_body"
        return 1
    fi

    if [[ "$host_with_path" == */* ]]; then
        page_path="/${host_with_path#*/}"
    else
        page_path="/"
    fi

    page_path=${page_path%%\?*}
    page_path=${page_path%%\#*}
    [[ -z "$page_path" ]] && page_path="/"

    candidate_bases=("https://$host" "http://$host")

    _loading "Checking LLM endpoints for $host"
    for base_url in ${candidate_bases[@]}; do
        for llm_path in ${candidate_paths[@]}; do
            llm_url="${base_url}${llm_path}"
            : > "$tmp_headers"
            : > "$tmp_body"
            curl -L -sS --max-time 20 -D "$tmp_headers" -o "$tmp_body" "$llm_url" >/dev/null 2>&1
            curl_rc=$?
            [[ $curl_rc -ne 0 ]] && continue

            status_code=$(awk 'toupper($1) ~ /^HTTP\// {c=$2} END {print c}' "$tmp_headers")
            if [[ "$status_code" == 2* && -s "$tmp_body" ]]; then
                _success "Found LLM file: $llm_url (HTTP $status_code)"
                _loading "Top 20 lines"
                head -n 20 "$tmp_body"
                echo ""
                active_base="$base_url"
                llm_found=1
                break
            fi
        done
        (( llm_found == 1 )) && break
    done

    if (( llm_found == 0 )); then
        _warning "No LLM file found at: /llm.txt, /llms.txt, /.well-known/llm.txt, /.well-known/llms.txt"
        active_base="https://$host"
    fi

    markdown_url="${active_base}${page_path}"
    _loading "Checking markdown negotiation for $markdown_url"
    : > "$tmp_headers"
    : > "$tmp_body"
    curl -L -sS --max-time 20 \
        -H "Accept: text/markdown, text/plain;q=0.9, */*;q=0.1" \
        -D "$tmp_headers" \
        -o "$tmp_body" \
        "$markdown_url" >/dev/null 2>&1
    curl_rc=$?

    if [[ $curl_rc -ne 0 ]]; then
        _warning "Unable to test markdown negotiation for $markdown_url"
        rm -f "$tmp_headers" "$tmp_body"
        return 0
    fi

    status_code=$(awk 'toupper($1) ~ /^HTTP\// {c=$2} END {print c}' "$tmp_headers")
    if [[ "$status_code" == "403" ]]; then
        _warning "Received HTTP 403 for markdown check. Retrying with Claude user-agent"
        : > "$tmp_headers"
        : > "$tmp_body"
        curl -L -sS --max-time 20 \
            -A "$claude_ua" \
            -H "Accept: text/markdown, text/plain;q=0.9, */*;q=0.1" \
            -D "$tmp_headers" \
            -o "$tmp_body" \
            "$markdown_url" >/dev/null 2>&1
        curl_rc=$?
        if [[ $curl_rc -ne 0 ]]; then
            _warning "Retry failed for markdown negotiation"
            rm -f "$tmp_headers" "$tmp_body"
            return 1
        fi
        status_code=$(awk 'toupper($1) ~ /^HTTP\// {c=$2} END {print c}' "$tmp_headers")
        if [[ "$status_code" == "403" ]]; then
            _error "Markdown check blocked (HTTP 403) even with Claude user-agent"
            rm -f "$tmp_headers" "$tmp_body"
            return 1
        fi
    fi

    if [[ "$status_code" != "200" ]]; then
        _warning "Markdown check did not return HTTP 200 (got ${status_code:-unknown})"
        rm -f "$tmp_headers" "$tmp_body"
        return 1
    fi

    content_type=$(awk -F': ' 'tolower($1)=="content-type" {print tolower($2)}' "$tmp_headers" | tail -n 1 | tr -d '\r')
    markdown_tokens=$(awk -F': ' 'tolower($1)=="x-markdown-tokens" {print $2}' "$tmp_headers" | tail -n 1 | tr -d '\r')
    content_signal=$(awk -F': ' 'tolower($1)=="content-signal" {print $2}' "$tmp_headers" | tail -n 1 | tr -d '\r')
    vary_header=$(awk -F': ' 'tolower($1)=="vary" {print tolower($2)}' "$tmp_headers" | tail -n 1 | tr -d '\r')

    if [[ "$status_code" == 2* ]]; then
        if [[ "$content_type" == *"text/markdown"* || -n "$markdown_tokens" ]]; then
            md_supported=1
        fi
    fi

    first_nonempty_line=$(grep -m 1 -E '[^[:space:]]' "$tmp_body")
    if [[ "$first_nonempty_line" == \#* ]]; then
        md_header_found=1
    fi

    if (( md_supported == 1 )); then
        _success "Markdown response detected for $markdown_url"
        if (( md_header_found == 1 )); then
            _success "Markdown header found (first non-empty line starts with #)"
        else
            _warning "Markdown detected but first non-empty line is not a markdown header (#...)"
            if [[ -n "$content_type" ]]; then
                _loading2 "markdown header: content-type: $content_type"
            fi
            if [[ -n "$markdown_tokens" ]]; then
                _loading2 "markdown header: x-markdown-tokens: $markdown_tokens"
            fi
            _loading2 "Top 20 lines"
            head -n 20 "$tmp_body"
        fi
    else
        _warning "No markdown response detected for $markdown_url"
        if (( md_header_found == 1 )); then
            _loading2 "Response appears markdown-like (header found)"
        fi
    fi

    [[ -n "$content_type" ]] && _log "content-type: $content_type"
    [[ -n "$markdown_tokens" ]] && _log "x-markdown-tokens: $markdown_tokens"
    [[ -n "$content_signal" ]] && _log "content-signal: $content_signal"
    [[ -n "$vary_header" ]] && _log "vary: $vary_header"
    rm -f "$tmp_headers" "$tmp_body"
}

# -- image-opt
# Optimize PNG/GIF/JPEG images using pngcrush, gifsicle, and jpegtran.
# - Auto-detects type by file extension unless -t is provided
# - Writes an optimized candidate next to the file (suffix .opt by default)
# - With -m/--commit, replaces the original if the optimized file is smaller
# - Reports size savings per file
#
# Usage:
#   image-opt [-t png|gif|jpg|jpeg|auto] [-m] [-s suffix] FILE [FILE ...]
#   image-opt -h
#
# Examples:
#   image-opt image.png
#   image-opt -t gif anim.gif
#   image-opt -m *.jpg
#
help_web[image-opt]='Optimize PNG/GIF/JPEG images (pngcrush/gifsicle/jpegtran|jpegoptim). Auto-detect JPEG tool; warns when using jpegoptim. Use -m to replace if smaller.'

image-opt () {
    local TYPE="auto" SUFFIX=".opt" COMMIT=0 VERBOSE=0 TOOL="auto" QUALITY=""
    typeset -g IMAGE_OPT_JPEGOPTIM_WARNED

    local _usage='Usage: image-opt [-t png|gif|jpg|jpeg|auto] [-m] [-s suffix] FILE [FILE ...]'
            local _help='Optimize PNG/GIF/JPEG images using pngcrush, gifsicle, and jpegtran (lossless) or jpegoptim (lossless/lossy).
        -t, --type       Force type (default: auto by file extension)
        -m, --commit     Replace original only if optimized is smaller
        -s, --suffix     Suffix for optimized candidate (default: .opt)
        -T, --tool       auto|jpegtran|jpegoptim (default: auto)
    -q, --quality    JPEG quality (0-100) for jpegoptim (enables lossy). If omitted, jpegoptim runs lossless.
    -v, --verbose    Verbose output
    -h, --help       This help'

    # Parse options using zparseopts (consumes recognized options from $@)
    local zparseopts_error=0
    local ARG_TYPE ARG_SUFFIX ARG_COMMIT ARG_VERBOSE ARG_HELP ARG_TOOL ARG_QUALITY
    zparseopts -D -E \
        t:=ARG_TYPE -type:=ARG_TYPE \
        s:=ARG_SUFFIX -suffix:=ARG_SUFFIX \
        m=ARG_COMMIT -commit=ARG_COMMIT \
        v=ARG_VERBOSE -verbose=ARG_VERBOSE \
        T:=ARG_TOOL -tool:=ARG_TOOL \
        q:=ARG_QUALITY -quality:=ARG_QUALITY \
        h=ARG_HELP -help=ARG_HELP || zparseopts_error=$?

    if (( zparseopts_error )); then
        _error "Invalid options"
        echo "$_usage"
        return 1
    fi

    if (( ${#ARG_HELP} )); then
        echo "$_usage"
        echo "\n$_help"
        return 0
    fi

    # Apply parsed options
    if (( ${#ARG_TYPE} )); then TYPE=${${ARG_TYPE[-1]}:l}; fi
    if (( ${#ARG_SUFFIX} )); then SUFFIX=${ARG_SUFFIX[-1]}; fi
    (( ${#ARG_COMMIT} )) && COMMIT=1
    (( ${#ARG_VERBOSE} )) && VERBOSE=1
    if (( ${#ARG_TOOL} )); then TOOL=${${ARG_TOOL[-1]}:l}; fi
    if (( ${#ARG_QUALITY} )); then QUALITY=${ARG_QUALITY[-1]}; fi

    # Resolve JPEG tool helper
    _resolve_jpeg_tool () { # echoes selected tool or empty if none
        local pref="$1"
        case "$pref" in
            auto|"")
                if command -v jpegtran >/dev/null 2>&1; then
                    echo jpegtran; return 0
                elif command -v jpegoptim >/dev/null 2>&1; then
                    echo jpegoptim; return 0
                else
                    echo ""; return 1
                fi
                ;;
            jpegtran)
                echo jpegtran; return 0 ;;
            jpegoptim)
                echo jpegoptim; return 0 ;;
            *)
                echo ""; return 1 ;;
        esac
    }

    if [[ $# -lt 1 ]]; then
        echo "$_usage"
        return 1
    fi

    # Helpers
    _image_opt_exists_or_warn () { # $1=cmd $2=display
        _cmd_exists "$1"
        if [[ $? != 0 ]]; then
            _error "Required tool not found: $2 ($1)" 0
            return 1
        fi
        return 0
    }

    _filesize_bytes () { # portable size via wc -c
        # usage: _filesize_bytes <path>
        if [[ -f "$1" ]]; then
            wc -c <"$1" | awk '{print $1}' 2>/dev/null
        fi
    }

    _percent_savings () { # $1=old $2=new
        local old=$1 new=$2
        if [[ -z $old || -z $new || $old -eq 0 ]]; then echo "0"; return; fi
        echo $(( (old - new) * 100 / old ))
    }

    _opt_one_png () { # $1=file $2=dest
        _image_opt_exists_or_warn pngcrush "pngcrush" || return 2
        pngcrush -q -brute "$1" "$2" >/dev/null 2>&1
    }

    _opt_one_gif () { # $1=file $2=dest
        _image_opt_exists_or_warn gifsicle "gifsicle" || return 2
        gifsicle -O3 "$1" -o "$2" >/dev/null 2>&1
    }

    _opt_one_jpg () { # $1=file $2=dest $3=tool
        local src="$1" dst="$2" tool="$3"
        case "$tool" in
            jpegoptim)
                _image_opt_exists_or_warn jpegoptim "jpegoptim" || return 2
                if [[ -z "$IMAGE_OPT_JPEGOPTIM_WARNED" ]]; then
                    if [[ -n "$QUALITY" ]]; then
                        _warning "Using jpegoptim with quality=$QUALITY (lossy). Verify output before committing." 0
                    else
                        _warning "Using jpegoptim in lossless mode. It can be lossy if --quality is provided." 0
                    fi
                    IMAGE_OPT_JPEGOPTIM_WARNED=1
                fi
                # jpegoptim works in-place; copy to destination then optimize
                command cp -f -- "$src" "$dst" || return 2
                local args=(--quiet)
                # Lossless defaults
                args+=(--strip-all --all-progressive)
                # If QUALITY provided, enable lossy via -m
                if [[ -n "$QUALITY" ]]; then
                    args+=(-m"$QUALITY")
                fi
                jpegoptim ${args[@]} "$dst" >/dev/null 2>&1 || return 2
                ;;
            *)
                _image_opt_exists_or_warn jpegtran "jpegtran" || return 2
                # Optimize and make progressive, strip metadata (lossless)
                jpegtran -copy none -optimize -progressive "$src" > "$dst" 2>/dev/null || return 2
                ;;
        esac
    }

    _detect_type () { # $1=filename -> echoes png|gif|jpg|unknown
        local f=${1:l}
        case "$f" in
            *.png) echo png ;;
            *.gif) echo gif ;;
            *.jpg|*.jpeg) echo jpg ;;
            *) echo unknown ;;
        esac
    }

    local total_saved=0 total_files=0 changed=0
    for f in "$@"; do
        if [[ ! -f "$f" ]]; then
            _warning "Skipping: not a file: $f" 0
            continue
        fi

        local t="$TYPE"
        [[ "$t" == "auto" ]] && t=$(_detect_type "$f")
        if [[ "$t" == "unknown" ]]; then
            _warning "Cannot determine image type for $f (use -t to specify)" 0
            continue
        fi

        local dest="$f$SUFFIX"
        rm -f -- "$dest" 2>/dev/null

        case "$t" in
            png) _opt_one_png "$f" "$dest" ;;
            gif) _opt_one_gif "$f" "$dest" ;;
            jpg|jpeg)
                local sel
                sel=$(_resolve_jpeg_tool "$TOOL")
                if [[ -z "$sel" ]]; then
                    _error "No JPEG optimizer found (install jpegtran or jpegoptim)" 0
                    rm -f -- "$dest"
                    continue
                fi
                _opt_one_jpg "$f" "$dest" "$sel" ;;
        esac
        local rc=$?
        if [[ $rc -ne 0 || ! -s "$dest" ]]; then
            _warning "Failed to optimize: $f" 0
            [[ -f "$dest" ]] && rm -f -- "$dest"
            continue
        fi

        local oldb newb saved pct
        oldb=$(_filesize_bytes "$f")
        newb=$(_filesize_bytes "$dest")
        if [[ -z "$oldb" || -z "$newb" ]]; then
            _warning "Could not stat sizes for $f" 0
            rm -f -- "$dest"
            continue
        fi
        (( saved = oldb - newb ))
        pct=$(_percent_savings "$oldb" "$newb")
        (( total_saved += (saved>0?saved:0) ))
        (( total_files += 1 ))

        if (( VERBOSE )); then
            _loading3 "$f: $oldb -> $newb bytes (saved ${saved} bytes, ${pct}%)"
        else
            echo "$f: $oldb -> $newb bytes (saved ${saved} bytes, ${pct}%)"
        fi

        if (( COMMIT )); then
            if (( newb < oldb )); then
                mv -f -- "$dest" "$f"
                (( changed += 1 ))
            else
                rm -f -- "$dest"
            fi
        fi
    done

    if (( total_files > 0 )); then
        _success "Optimized $total_files file(s). Total saved: $total_saved bytes" 
        (( COMMIT )) && _loading "Committed replacements: $changed"
    fi
}

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

