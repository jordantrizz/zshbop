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

# ==============================================
# -- _http_test_color_code - return ANSI color code for a result level
# ==============================================
function _http_test_color_code () {
    local level="$1"

    if [[ ! -t 1 ]]; then
        return 0
    fi

    case "$level" in
        PASS)
            printf '\033[32m'
            ;;
        WARN|SKIP)
            printf '\033[33m'
            ;;
        FAIL)
            printf '\033[31m'
            ;;
        INFO)
            printf '\033[36m'
            ;;
        *)
            ;;
    esac
}

# ==============================================
# -- _http_test_reset_code - return ANSI reset code when stdout is a terminal
# ==============================================
function _http_test_reset_code () {
    if [[ -t 1 ]]; then
        printf '\033[0m'
    fi
}

# ==============================================
# -- _http_test_format_status - format a summary status with optional color
# ==============================================
function _http_test_format_status () {
    local label="$1"
    local color_value=""
    local reset_value=""

    color_value=$(_http_test_color_code "$label")
    reset_value=$(_http_test_reset_code)

    if [[ -n "$color_value" ]]; then
        printf '%b%-8s%b' "$color_value" "$label" "$reset_value"
    else
        printf '%-8s' "$label"
    fi
}

# ==============================================
# -- _http_test_print_line - print a colored status line when stdout is a terminal
# ==============================================
function _http_test_print_line () {
    local level="$1"
    local label="$2"
    local message="$3"
    local color_value=""
    local color_reset=""

    color_value=$(_http_test_color_code "$level")
    color_reset=$(_http_test_reset_code)

    if [[ -n "$color_value" ]]; then
        printf "%b[%-4s]%b %s\n" "$color_value" "$label" "$color_reset" "$message"
    else
        printf "[%-4s] %s\n" "$label" "$message"
    fi
}

# ==============================================
# -- _http_test_print_section - print a section header for http-test output
# ==============================================
function _http_test_print_section () {
    local title="$1"
    local color_value=""
    local color_reset=""

    color_value=$(_http_test_color_code "INFO")
    color_reset=$(_http_test_reset_code)

    echo ""
    if [[ -n "$color_value" ]]; then
        printf "%b%s%b\n" "$color_value" "== ${title} ==" "$color_reset"
    else
        echo "== ${title} =="
    fi
}

# ==============================================
# -- _http_test_record_result - store summary status/detail in associative arrays
# ==============================================
function _http_test_record_result () {
    local key="$1"
    local result_status="$2"
    local detail="$3"

    HTTP_TEST_SUMMARY_STATUS[$key]="$result_status"
    HTTP_TEST_SUMMARY_DETAIL[$key]="$detail"
    HTTP_TEST_SUMMARY_ORDER+=("$key")
}

# ==============================================
# -- _http_test_update_exit_state - track the highest severity seen
# ==============================================
function _http_test_update_exit_state () {
    local result_status="$1"

    if [[ "$result_status" == "FAIL" ]]; then
        HTTP_TEST_EXIT_CODE=2
    elif [[ "$result_status" == "WARN" && $HTTP_TEST_EXIT_CODE -lt 2 ]]; then
        HTTP_TEST_EXIT_CODE=1
    fi
}

# ==============================================
# -- _http_test_warn_missing_dep - warn once for optional missing dependencies
# ==============================================
function _http_test_warn_missing_dep () {
    local dep_name="$1"
    local message="$2"

    if [[ -z "${HTTP_TEST_MISSING_DEPS[$dep_name]}" ]]; then
        HTTP_TEST_MISSING_DEPS[$dep_name]=1
        _http_test_print_line "WARN" "WARN" "$message"
    fi
}

# ==============================================
# -- _http_test_parse_url - normalize the user-provided URL into globals
# ==============================================
function _http_test_parse_url () {
    local input_value="$1"
    local normalized_input="$input_value"
    local rest_value=""
    local authority_value=""
    local host_port_value=""
    local path_value="/"
    local scheme_value=""
    local port_value=""

    HTTP_TEST_INPUT_SCHEME=""
    HTTP_TEST_INPUT_HOST=""
    HTTP_TEST_INPUT_PORT=""
    HTTP_TEST_INPUT_PATH_QUERY="/"
    HTTP_TEST_INPUT_HAS_SCHEME=0
    HTTP_TEST_INPUT_HAS_PORT=0

    normalized_input=${normalized_input%%\#*}

    if [[ "$normalized_input" == (#b)([[:alpha:]][[:alnum:]+.-]#)://(*) ]]; then
        scheme_value="${match[1]:l}"
        rest_value="${match[2]}"
        HTTP_TEST_INPUT_HAS_SCHEME=1
    else
        rest_value="$normalized_input"
    fi

    authority_value="$rest_value"
    if [[ "$rest_value" == */* ]]; then
        authority_value="${rest_value%%/*}"
        path_value="/${rest_value#*/}"
    fi

    [[ -z "$path_value" ]] && path_value="/"
    host_port_value="$authority_value"

    if [[ "$host_port_value" == \[*\]* ]]; then
        HTTP_TEST_INPUT_HOST="${host_port_value%%]*}]"
        HTTP_TEST_INPUT_HOST="${HTTP_TEST_INPUT_HOST#[}"
        if [[ "$host_port_value" == *]:* ]]; then
            port_value="${host_port_value##*:}"
            HTTP_TEST_INPUT_HAS_PORT=1
        fi
    else
        HTTP_TEST_INPUT_HOST="${host_port_value%%:*}"
        if [[ "$host_port_value" == *:* ]]; then
            port_value="${host_port_value##*:}"
            HTTP_TEST_INPUT_HAS_PORT=1
        fi
    fi

    if [[ -z "$HTTP_TEST_INPUT_HOST" ]]; then
        return 1
    fi

    HTTP_TEST_INPUT_SCHEME="$scheme_value"
    HTTP_TEST_INPUT_PORT="$port_value"
    HTTP_TEST_INPUT_PATH_QUERY="$path_value"
    return 0
}

# ==============================================
# -- _http_test_build_target_url - build a normalized URL for a scheme
# ==============================================
function _http_test_build_target_url () {
    local scheme_value="$1"
    local host_value="$HTTP_TEST_INPUT_HOST"
    local port_segment=""

    if (( HTTP_TEST_INPUT_HAS_PORT )); then
        port_segment=":${HTTP_TEST_INPUT_PORT}"
    fi

    printf "%s://%s%s%s" "$scheme_value" "$host_value" "$port_segment" "$HTTP_TEST_INPUT_PATH_QUERY"
}

# ==============================================
# -- _http_test_curl_supports_http3 - return success when curl advertises HTTP3
# ==============================================
function _http_test_curl_supports_http3 () {
    if [[ -n "$HTTP_TEST_HTTP3_SUPPORT_CACHE" ]]; then
        [[ "$HTTP_TEST_HTTP3_SUPPORT_CACHE" == "1" ]]
        return $?
    fi

    if curl --version 2>/dev/null | grep -qi 'HTTP3'; then
        HTTP_TEST_HTTP3_SUPPORT_CACHE="1"
        return 0
    fi

    HTTP_TEST_HTTP3_SUPPORT_CACHE="0"
    return 1
}

# ==============================================
# -- _http_test_build_resolve_args - emit curl --resolve arguments for host override
# ==============================================
function _http_test_build_resolve_args () {
    if [[ -n "$HTTP_TEST_IP_OVERRIDE" ]]; then
        printf -- "--resolve\n%s:80:%s\n--resolve\n%s:443:%s\n" \
            "$HTTP_TEST_INPUT_HOST" "$HTTP_TEST_IP_OVERRIDE" "$HTTP_TEST_INPUT_HOST" "$HTTP_TEST_IP_OVERRIDE"
    fi
}

# ==============================================
# -- _http_test_collect_headers - run curl HEAD request and store output in globals
# ==============================================
function _http_test_collect_headers () {
    local protocol_flag="$1"
    local target_url="$2"
    local verbose_mode="$3"
    local insecure_mode="$4"
    local tmp_headers=""
    local tmp_verbose=""
    local curl_exit=0
    local -a curl_args
    local -a resolve_args

    HTTP_TEST_LAST_HEADERS=""
    HTTP_TEST_LAST_VERBOSE=""
    HTTP_TEST_LAST_PROTOCOL=""
    HTTP_TEST_LAST_STATUS=""
    HTTP_TEST_LAST_REDIRECT=""
    HTTP_TEST_LAST_TIME=""
    HTTP_TEST_LAST_REMOTE_IP=""
    HTTP_TEST_LAST_EFFECTIVE_URL=""
    HTTP_TEST_LAST_ERROR=""

    tmp_headers=$(mktemp) || {
        HTTP_TEST_LAST_ERROR="Unable to create temporary file"
        return 1
    }

    tmp_verbose=$(mktemp) || {
        rm -f "$tmp_headers"
        HTTP_TEST_LAST_ERROR="Unable to create temporary file"
        return 1
    }

    resolve_args=()
    if [[ -n "$HTTP_TEST_IP_OVERRIDE" ]]; then
        resolve_args=(
            "--resolve" "${HTTP_TEST_INPUT_HOST}:80:${HTTP_TEST_IP_OVERRIDE}"
            "--resolve" "${HTTP_TEST_INPUT_HOST}:443:${HTTP_TEST_IP_OVERRIDE}"
        )
    fi
    curl_args=(
        "$protocol_flag"
        "--silent"
        "--show-error"
        "--location"
        "--max-redirs" "10"
        "--max-time" "10"
        "--connect-timeout" "10"
        "--head"
        "--dump-header" "$tmp_headers"
        "--output" "/dev/null"
        "--write-out" "__HTTP_TEST__|%{http_code}|%{time_total}|%{redirect_url}|%{http_version}|%{remote_ip}|%{url_effective}"
    )

    if [[ "$insecure_mode" == "1" ]]; then
        curl_args+=("--insecure")
    fi

    if (( ${#resolve_args[@]} > 0 )); then
        curl_args+=("${resolve_args[@]}")
    fi

    curl_args+=("$target_url")

    HTTP_TEST_LAST_PROTOCOL="$protocol_flag"
    HTTP_TEST_LAST_VERBOSE=$(curl "${curl_args[@]}" 2>"$tmp_verbose")
    curl_exit=$?

    if [[ -s "$tmp_headers" ]]; then
        HTTP_TEST_LAST_HEADERS=$(<"$tmp_headers")
    fi
    if [[ -s "$tmp_verbose" && "$verbose_mode" == "1" ]]; then
        HTTP_TEST_LAST_VERBOSE+=$'\n'
        HTTP_TEST_LAST_VERBOSE+=$(<"$tmp_verbose")
    fi
    if [[ -s "$tmp_verbose" && $curl_exit -ne 0 && -z "$HTTP_TEST_LAST_ERROR" ]]; then
        HTTP_TEST_LAST_ERROR=$(tail -n 1 "$tmp_verbose")
    fi

    rm -f "$tmp_headers" "$tmp_verbose"

    if [[ $curl_exit -ne 0 ]]; then
        [[ -z "$HTTP_TEST_LAST_ERROR" ]] && HTTP_TEST_LAST_ERROR="curl exited with code $curl_exit"
        return $curl_exit
    fi

    HTTP_TEST_LAST_STATUS=$(echo "$HTTP_TEST_LAST_VERBOSE" | awk -F'|' '/^__HTTP_TEST__/ {print $2; exit}')
    HTTP_TEST_LAST_TIME=$(echo "$HTTP_TEST_LAST_VERBOSE" | awk -F'|' '/^__HTTP_TEST__/ {print $3; exit}')
    HTTP_TEST_LAST_REDIRECT=$(echo "$HTTP_TEST_LAST_VERBOSE" | awk -F'|' '/^__HTTP_TEST__/ {print $4; exit}')
    HTTP_TEST_LAST_HTTP_VERSION=$(echo "$HTTP_TEST_LAST_VERBOSE" | awk -F'|' '/^__HTTP_TEST__/ {print $5; exit}')
    HTTP_TEST_LAST_REMOTE_IP=$(echo "$HTTP_TEST_LAST_VERBOSE" | awk -F'|' '/^__HTTP_TEST__/ {print $6; exit}')
    HTTP_TEST_LAST_EFFECTIVE_URL=$(echo "$HTTP_TEST_LAST_VERBOSE" | awk -F'|' '/^__HTTP_TEST__/ {print $7; exit}')
    HTTP_TEST_LAST_VERBOSE=$(echo "$HTTP_TEST_LAST_VERBOSE" | sed '/^__HTTP_TEST__/d')
    return 0
}

# ==============================================
# -- _http_test_header_value - return the last matching header value
# ==============================================
function _http_test_header_value () {
    local header_name="$1"
    printf "%s\n" "$HTTP_TEST_LAST_HEADERS" | awk -F':' -v name="$header_name" '
        BEGIN { IGNORECASE = 1 }
        $0 ~ /^[[:space:]]*HTTP\// { next }
        tolower($1) == tolower(name) {
            sub(/^[^:]*:[[:space:]]*/, "", $0)
            value=$0
        }
        END { gsub(/\r/, "", value); print value }
    '
}

# ==============================================
# -- run_test_http1 - test HTTP/1.1 headers for a URL
# ==============================================
function run_test_http1 () {
    local target_url="$1"
    local summary_key="$2"
    local insecure_mode="$3"
    local result_status="PASS"
    local detail=""

    _http_test_collect_headers "--http1.1" "$target_url" "$HTTP_TEST_VERBOSE" "$insecure_mode"
    if [[ $? -ne 0 ]]; then
        result_status="FAIL"
        detail="HTTP/1.1 request failed for $target_url: ${HTTP_TEST_LAST_ERROR:-timeout or connection error}"
    elif [[ -z "$HTTP_TEST_LAST_STATUS" || "$HTTP_TEST_LAST_STATUS" == "000" ]]; then
        result_status="FAIL"
        detail="HTTP/1.1 request returned no valid status for $target_url"
    else
        detail="HTTP/1.1 status ${HTTP_TEST_LAST_STATUS:-unknown} in ${HTTP_TEST_LAST_TIME:-n/a}s"
        if [[ "$HTTP_TEST_LAST_STATUS" == 3* && -n "$HTTP_TEST_LAST_REDIRECT" ]]; then
            detail+=" redirect -> $HTTP_TEST_LAST_REDIRECT"
        fi
    fi

    _http_test_record_result "$summary_key" "$result_status" "$detail"
    _http_test_update_exit_state "$result_status"
    _http_test_print_line "$result_status" "$result_status" "$detail"

    HTTP_TEST_CAPTURED_HEADERS[http1]="$HTTP_TEST_LAST_HEADERS"
    HTTP_TEST_CAPTURED_VERBOSE[http1]="$HTTP_TEST_LAST_VERBOSE"
}

# ==============================================
# -- run_test_http2 - test HTTP/2 headers for a URL
# ==============================================
function run_test_http2 () {
    local target_url="$1"
    local summary_key="$2"
    local insecure_mode="$3"
    local result_status="PASS"
    local detail=""

    _http_test_collect_headers "--http2" "$target_url" "$HTTP_TEST_VERBOSE" "$insecure_mode"
    if [[ $? -ne 0 ]]; then
        result_status="FAIL"
        detail="HTTP/2 request failed for $target_url: ${HTTP_TEST_LAST_ERROR:-timeout or connection error}"
    elif [[ -z "$HTTP_TEST_LAST_STATUS" || "$HTTP_TEST_LAST_STATUS" == "000" ]]; then
        result_status="FAIL"
        detail="HTTP/2 request returned no valid status for $target_url"
    else
        if [[ "$HTTP_TEST_LAST_HTTP_VERSION" != "2" ]]; then
            result_status="WARN"
            detail="HTTP/2 not negotiated for $target_url (reported version ${HTTP_TEST_LAST_HTTP_VERSION:-unknown})"
        else
            detail="HTTP/2 negotiated for $target_url with status ${HTTP_TEST_LAST_STATUS:-unknown} in ${HTTP_TEST_LAST_TIME:-n/a}s"
        fi
    fi

    _http_test_record_result "$summary_key" "$result_status" "$detail"
    _http_test_update_exit_state "$result_status"
    _http_test_print_line "$result_status" "$result_status" "$detail"

    HTTP_TEST_CAPTURED_HEADERS[http2]="$HTTP_TEST_LAST_HEADERS"
    HTTP_TEST_CAPTURED_VERBOSE[http2]="$HTTP_TEST_LAST_VERBOSE"
}

# ==============================================
# -- run_test_http3 - test HTTP/3 headers for a URL when curl supports it
# ==============================================
function run_test_http3 () {
    local target_url="$1"
    local summary_key="$2"
    local insecure_mode="$3"
    local result_status="PASS"
    local detail=""

    if ! _http_test_curl_supports_http3; then
        result_status="SKIP"
        detail="HTTP/3 not supported by local curl build"
        _http_test_record_result "$summary_key" "$result_status" "$detail"
        _http_test_print_line "$result_status" "$result_status" "$detail"
        return 0
    fi

    _http_test_collect_headers "--http3" "$target_url" "$HTTP_TEST_VERBOSE" "$insecure_mode"
    if [[ $? -ne 0 ]]; then
        result_status="FAIL"
        detail="HTTP/3 request failed for $target_url: ${HTTP_TEST_LAST_ERROR:-timeout or connection error}"
    elif [[ -z "$HTTP_TEST_LAST_STATUS" || "$HTTP_TEST_LAST_STATUS" == "000" ]]; then
        result_status="FAIL"
        detail="HTTP/3 request returned no valid status for $target_url"
    else
        if [[ "$HTTP_TEST_LAST_HTTP_VERSION" != "3" ]]; then
            result_status="WARN"
            detail="HTTP/3 not negotiated for $target_url (reported version ${HTTP_TEST_LAST_HTTP_VERSION:-unknown})"
        else
            detail="HTTP/3 negotiated for $target_url with status ${HTTP_TEST_LAST_STATUS:-unknown} in ${HTTP_TEST_LAST_TIME:-n/a}s"
        fi
    fi

    _http_test_record_result "$summary_key" "$result_status" "$detail"
    _http_test_update_exit_state "$result_status"
    _http_test_print_line "$result_status" "$result_status" "$detail"

    HTTP_TEST_CAPTURED_HEADERS[http3]="$HTTP_TEST_LAST_HEADERS"
    HTTP_TEST_CAPTURED_VERBOSE[http3]="$HTTP_TEST_LAST_VERBOSE"
}

# ==============================================
# -- check_headers - validate response headers for duplicates and malformed fields
# ==============================================
function check_headers () {
    local header_block="$1"
    local summary_key="$2"
    local result_status="PASS"
    local detail="No header issues detected"
    local issue_count=0
    local line_value=""
    local header_name=""
    local header_value=""
    local header_key=""
    typeset -A seen_headers
    local -a issues

    while IFS= read -r line_value; do
        line_value=${line_value%$'\r'}
        [[ -z "$line_value" ]] && continue
        [[ "$line_value" == HTTP/* ]] && continue
        [[ "$line_value" != *:* ]] && continue

        header_name="${line_value%%:*}"
        header_value="${line_value#*:}"
        header_value="${header_value#${header_value%%[![:space:]]*}}"
        header_key="${header_name:l}"

        if [[ -n "${seen_headers[$header_key]}" ]]; then
            issues+=("duplicate header ${header_name}: ${header_value}")
            (( issue_count++ ))
        else
            seen_headers[$header_key]=1
        fi

        if [[ "$header_name" != "${header_name##[[:space:]]#}" || "$header_name" != "${header_name%%[[:space:]]#}" || "$header_name" == *" "* ]]; then
            issues+=("invalid whitespace in header name ${header_name}")
            (( issue_count++ ))
        fi

        if [[ ! "$header_name" =~ '^[!#$%&'"'"'*+.^_`|~0-9A-Za-z-]+$' ]]; then
            issues+=("invalid token characters in header name ${header_name}")
            (( issue_count++ ))
        fi

        if [[ "$header_value" == "" ]]; then
            issues+=("empty header value for ${header_name}")
            (( issue_count++ ))
        fi

        if [[ "${header_name:l}" == "set-cookie" ]]; then
            if [[ "${header_value%%;*}" != *=* ]]; then
                issues+=("malformed Set-Cookie ${header_value}")
                (( issue_count++ ))
            fi
        fi
    done <<< "$header_block"

    if (( issue_count > 0 )); then
        result_status="FAIL"
        detail="${issue_count} header issue(s): ${issues[*]}"
    fi

    _http_test_record_result "$summary_key" "$result_status" "$detail"
    _http_test_update_exit_state "$result_status"
    _http_test_print_line "$result_status" "$result_status" "$detail"
}

# ==============================================
# -- check_redirects - follow redirects and flag loops or mixed-scheme chains
# ==============================================
function check_redirects () {
    local target_url="$1"
    local summary_key="$2"
    local insecure_mode="$3"
    local result_status="PASS"
    local detail="No redirects"
    local current_url="$target_url"
    local redirect_url=""
    local hop_status_code=""
    local previous_scheme=""
    local current_scheme=""
    local mixed_scheme=0
    local loop_detected=0
    local hop_count=0
    typeset -A seen_urls
    while (( hop_count < 10 )); do
        if [[ -n "${seen_urls[$current_url]}" ]]; then
            loop_detected=1
            break
        fi
        seen_urls[$current_url]=1

        _http_test_collect_headers "--http1.1" "$current_url" "0" "$insecure_mode"
        if [[ $? -ne 0 ]]; then
            result_status="FAIL"
            detail="Redirect chain failed for $current_url: ${HTTP_TEST_LAST_ERROR:-timeout or connection error}"
            _http_test_record_result "$summary_key" "$result_status" "$detail"
            _http_test_update_exit_state "$result_status"
            _http_test_print_line "$result_status" "$result_status" "$detail"
            return 0
        fi

        hop_status_code="${HTTP_TEST_LAST_STATUS:-000}"
        redirect_url="$HTTP_TEST_LAST_REDIRECT"
        current_scheme="${current_url%%:*}"
        if [[ -n "$previous_scheme" && "$previous_scheme" != "$current_scheme" ]]; then
            mixed_scheme=1
        fi
        previous_scheme="$current_scheme"
        _http_test_print_line "INFO" "HOP" "HEAD ${current_url} -> ${hop_status_code}"
        (( hop_count++ ))

        if [[ "$hop_status_code" != 3* || -z "$redirect_url" ]]; then
            break
        fi
        current_url="$redirect_url"
    done

    detail="${hop_count} redirect hop(s) checked"
    if (( loop_detected )); then
        result_status="FAIL"
        detail+="; redirect loop detected"
    elif (( hop_count == 10 )) && [[ "$hop_status_code" == 3* && -n "$redirect_url" ]]; then
        result_status="WARN"
        detail+="; redirect limit reached"
    elif (( mixed_scheme )); then
        result_status="WARN"
        detail+="; chain mixes http and https"
    fi

    _http_test_record_result "$summary_key" "$result_status" "$detail"
    _http_test_update_exit_state "$result_status"
    _http_test_print_line "$result_status" "$result_status" "$detail"
}

# ==============================================
# -- check_tls - inspect negotiated TLS version and certificate basics for HTTPS targets
# ==============================================
function check_tls () {
    local target_url="$1"
    local summary_key="$2"
    local insecure_mode="$3"
    local result_status="PASS"
    local detail=""
    local s_client_output=""
    local openssl_output=""
    local cert_enddate=""
    local cert_subject=""
    local cert_san=""
    local tls_version=""
    local expiry_epoch=""
    local now_epoch=""
    local days_left=""
    local host_name="$HTTP_TEST_INPUT_HOST"
    local connect_target="$HTTP_TEST_INPUT_HOST"

    if [[ "$target_url" != https://* ]]; then
        _http_test_record_result "$summary_key" "SKIP" "TLS checks skipped for non-HTTPS target"
        _http_test_print_line "SKIP" "SKIP" "TLS checks skipped for non-HTTPS target"
        return 0
    fi

    if (( ! $+commands[openssl] )); then
        _http_test_warn_missing_dep "openssl" "openssl not installed; TLS details reduced"
        tls_version=$(_http_test_header_value "strict-transport-security")
        if [[ -n "$tls_version" ]]; then
            detail="HSTS present but openssl unavailable for deeper TLS inspection"
            result_status="WARN"
        else
            detail="openssl unavailable; unable to inspect TLS certificate details"
            result_status="WARN"
        fi
        _http_test_record_result "$summary_key" "$result_status" "$detail"
        _http_test_update_exit_state "$result_status"
        _http_test_print_line "$result_status" "$result_status" "$detail"
        return 0
    fi

    if [[ -n "$HTTP_TEST_IP_OVERRIDE" ]]; then
        connect_target="$HTTP_TEST_IP_OVERRIDE"
    fi

    s_client_output=$(echo | openssl s_client -connect "${connect_target}:443" -servername "$HTTP_TEST_INPUT_HOST" 2>/dev/null)
    openssl_output=$(printf "%s\n" "$s_client_output" | openssl x509 -noout -enddate -subject -ext subjectAltName 2>/dev/null)
    if [[ -z "$openssl_output" ]]; then
        result_status="FAIL"
        detail="Unable to read certificate via openssl for ${connect_target}:443"
        _http_test_record_result "$summary_key" "$result_status" "$detail"
        _http_test_update_exit_state "$result_status"
        _http_test_print_line "$result_status" "$result_status" "$detail"
        return 0
    fi

    cert_enddate=$(printf "%s\n" "$openssl_output" | awk -F'=' '/^notAfter=/ {print $2; exit}')
    cert_subject=$(printf "%s\n" "$openssl_output" | awk -F'=' '/^subject=/ {print $2; exit}')
    cert_san=$(printf "%s\n" "$openssl_output" | awk 'BEGIN { capture = 0 } /X509v3 Subject Alternative Name/ { capture = 1; next } capture == 1 { gsub(/^[[:space:]]+/, "", $0); print; exit }')
    tls_version=$(printf "%s\n" "$s_client_output" | awk -F': *' '/Protocol[[:space:]]*:/ {print $2; exit}')
    [[ -z "$tls_version" ]] && tls_version="unknown"

    if [[ "$tls_version" == "TLSv1" || "$tls_version" == "TLSv1.0" || "$tls_version" == "TLSv1.1" ]]; then
        result_status="WARN"
    fi

    if [[ -n "$cert_enddate" ]]; then
        expiry_epoch=$(date -j -f "%b %e %T %Y %Z" "$cert_enddate" +%s 2>/dev/null)
        now_epoch=$(date +%s)
        if [[ -n "$expiry_epoch" ]]; then
            days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
            if (( expiry_epoch < now_epoch )); then
                result_status="FAIL"
                detail="Certificate expired on ${cert_enddate}"
            elif (( days_left < 30 )) && [[ "$result_status" != "FAIL" ]]; then
                result_status="WARN"
                detail="Certificate expires in ${days_left} day(s) on ${cert_enddate}"
            fi
        fi
    fi

    if [[ "$cert_subject" != *"CN=${host_name}"* && "$cert_san" != *"DNS:${host_name}"* ]]; then
        result_status="FAIL"
        detail="Certificate CN/SAN does not match ${host_name}"
    fi

    if [[ -z "$detail" ]]; then
        detail="TLS ${tls_version}; certificate valid for ${host_name}; expires ${cert_enddate:-unknown}"
    else
        detail+="; TLS ${tls_version}; subject ${cert_subject:-unknown}"
    fi

    if [[ -n "$(_http_test_header_value strict-transport-security)" ]]; then
        detail+="; HSTS present"
    else
        if [[ "$result_status" == "PASS" ]]; then
            result_status="WARN"
        fi
        detail+="; HSTS missing"
    fi

    _http_test_record_result "$summary_key" "$result_status" "$detail"
    _http_test_update_exit_state "$result_status"
    _http_test_print_line "$result_status" "$result_status" "$detail"
}

# ==============================================
# -- check_dns - print A and AAAA DNS resolution, noting any IP override
# ==============================================
function check_dns () {
    local summary_key="$1"
    local result_status="PASS"
    local detail=""
    local a_records=""
    local aaaa_records=""

    if (( $+commands[dig] )); then
        a_records=$(dig +short A "$HTTP_TEST_INPUT_HOST" | paste -sd ',' -)
        aaaa_records=$(dig +short AAAA "$HTTP_TEST_INPUT_HOST" | paste -sd ',' -)
    elif (( $+commands[nslookup] )); then
        _http_test_warn_missing_dep "dig" "dig not installed; falling back to nslookup for DNS data"
        a_records=$(nslookup -query=A "$HTTP_TEST_INPUT_HOST" 2>/dev/null | awk '/^Address: / {print $2}' | paste -sd ',' -)
        aaaa_records=$(nslookup -query=AAAA "$HTTP_TEST_INPUT_HOST" 2>/dev/null | awk '/^Address: / {print $2}' | paste -sd ',' -)
    else
        result_status="WARN"
        detail="Neither dig nor nslookup is available; DNS details unavailable"
        _http_test_record_result "$summary_key" "$result_status" "$detail"
        _http_test_update_exit_state "$result_status"
        _http_test_print_line "$result_status" "$result_status" "$detail"
        return 0
    fi

    [[ -z "$a_records" ]] && a_records="none"
    [[ -z "$aaaa_records" ]] && aaaa_records="none"
    detail="A=${a_records} AAAA=${aaaa_records}"
    if [[ -n "$HTTP_TEST_IP_OVERRIDE" ]]; then
        detail+="; testing via IP override: ${HTTP_TEST_IP_OVERRIDE}"
    fi

    _http_test_record_result "$summary_key" "$result_status" "$detail"
    _http_test_update_exit_state "$result_status"
    _http_test_print_line "$result_status" "$result_status" "$detail"
}

# ==============================================
# -- detect_cdn - look for Cloudflare/CDN response headers
# ==============================================
function detect_cdn () {
    local header_block="$1"
    local summary_key="$2"
    local result_status="PASS"
    local detail="No obvious CDN headers detected"
    local server_header=""
    local cf_ray=""
    local served_by=""

    HTTP_TEST_LAST_HEADERS="$header_block"
    server_header=$(_http_test_header_value server)
    cf_ray=$(_http_test_header_value cf-ray)
    served_by=$(_http_test_header_value x-served-by)

    if [[ -n "$cf_ray" || "${server_header:l}" == *cloudflare* || -n "$served_by" ]]; then
        result_status="WARN"
        detail="CDN detected"
        [[ -n "$cf_ray" ]] && detail+="; CF-Ray=${cf_ray}"
        [[ -n "$server_header" ]] && detail+="; Server=${server_header}"
        [[ -n "$served_by" ]] && detail+="; x-served-by=${served_by}"
        detail+="; use --ip <origin_ip> to test origin directly"
    fi

    _http_test_record_result "$summary_key" "$result_status" "$detail"
    _http_test_update_exit_state "$result_status"
    _http_test_print_line "$result_status" "$result_status" "$detail"
}

# ==============================================
# -- print_summary - print the final summary table for http-test
# ==============================================
function print_summary () {
    local summary_key=""
    local result_status=""
    local detail=""
    local formatted_status=""

    _http_test_print_section "SUMMARY"
    printf "%-8s  %-24s %s\n" "STATUS" "CHECK" "DETAIL"
    printf "%-8s  %-24s %s\n" "------" "-----" "------"
    for summary_key in "${HTTP_TEST_SUMMARY_ORDER[@]}"; do
        result_status="${HTTP_TEST_SUMMARY_STATUS[$summary_key]}"
        detail="${HTTP_TEST_SUMMARY_DETAIL[$summary_key]}"
        formatted_status=$(_http_test_format_status "$result_status")
        printf "%b  %-24s %s\n" "$formatted_status" "$summary_key" "$detail"
    done
}

# ==============================================
# -- http-test - perform HTTP, DNS, redirect, and TLS diagnostics for a URL
# ==============================================
help_web[http-test]='Perform HTTP diagnostics for a URL across HTTP/1.1, HTTP/2, HTTP/3, redirects, TLS, DNS, and CDN headers'
function http-test () {
    local usage_text="Usage: http-test <url> [--ip <ip_address>] [--verbose] [--help]"
    local target_input=""
    local target_url=""
    local target_scheme=""
    local insecure_mode="0"
    local summary_prefix=""
    local -a schemes_to_test

    if (( ! $+commands[curl] )); then
        _error "curl is required for http-test"
        return 2
    fi

    HTTP_TEST_VERBOSE=0
    HTTP_TEST_IP_OVERRIDE=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                echo "$usage_text"
                echo ""
                echo "Arguments:"
                echo "  <url>           Required. URL or hostname to test"
                echo "  --ip <address>  Override DNS resolution using curl --resolve"
                echo "  --verbose       Show verbose curl and response header output"
                return 0
                ;;
            -v|--verbose)
                HTTP_TEST_VERBOSE=1
                ;;
            --ip)
                shift
                if [[ -z "$1" ]]; then
                    _error "--ip requires an address"
                    echo "$usage_text"
                    return 2
                fi
                HTTP_TEST_IP_OVERRIDE="$1"
                ;;
            --ip=*)
                HTTP_TEST_IP_OVERRIDE="${1#--ip=}"
                ;;
            --*)
                _error "Unknown option: $1"
                echo "$usage_text"
                return 2
                ;;
            *)
                if [[ -z "$target_input" ]]; then
                    target_input="$1"
                else
                    _error "Unexpected argument: $1"
                    echo "$usage_text"
                    return 2
                fi
                ;;
        esac
        shift
    done

    if [[ -z "$target_input" ]]; then
        echo "$usage_text"
        return 2
    fi

    typeset -gA HTTP_TEST_SUMMARY_STATUS
    typeset -gA HTTP_TEST_SUMMARY_DETAIL
    typeset -gA HTTP_TEST_MISSING_DEPS
    typeset -gA HTTP_TEST_CAPTURED_HEADERS
    typeset -gA HTTP_TEST_CAPTURED_VERBOSE
    typeset -ga HTTP_TEST_SUMMARY_ORDER
    HTTP_TEST_SUMMARY_STATUS=()
    HTTP_TEST_SUMMARY_DETAIL=()
    HTTP_TEST_MISSING_DEPS=()
    HTTP_TEST_CAPTURED_HEADERS=()
    HTTP_TEST_CAPTURED_VERBOSE=()
    HTTP_TEST_SUMMARY_ORDER=()
    HTTP_TEST_HTTP3_SUPPORT_CACHE=""
    HTTP_TEST_EXIT_CODE=0

    if ! _http_test_parse_url "$target_input"; then
        _error "Unable to parse URL: $target_input"
        return 2
    fi

    if (( HTTP_TEST_INPUT_HAS_PORT )) && (( HTTP_TEST_INPUT_HAS_SCHEME )); then
        schemes_to_test=("$HTTP_TEST_INPUT_SCHEME")
    else
        schemes_to_test=(http https)
    fi

    _http_test_print_section "HTTP TEST"
    _http_test_print_line "INFO" "INFO" "Host: ${HTTP_TEST_INPUT_HOST}"
    if [[ -n "$HTTP_TEST_IP_OVERRIDE" ]]; then
        _http_test_print_line "INFO" "INFO" "testing via IP override: ${HTTP_TEST_IP_OVERRIDE}"
    fi

    check_dns "dns"

    for target_scheme in "${schemes_to_test[@]}"; do
        target_url=$(_http_test_build_target_url "$target_scheme")
        summary_prefix="${target_scheme}"
        insecure_mode="0"
        HTTP_TEST_CAPTURED_HEADERS=()
        HTTP_TEST_CAPTURED_VERBOSE=()

        if [[ "$target_scheme" == "https" && -n "$HTTP_TEST_IP_OVERRIDE" ]]; then
            insecure_mode="1"
            _http_test_print_line "WARN" "WARN" "HTTPS origin override enables --insecure for self-signed certificates"
        fi

        _http_test_print_section "$target_scheme://${HTTP_TEST_INPUT_HOST}"
        run_test_http1 "$target_url" "${summary_prefix}-http1" "$insecure_mode"
        check_headers "$HTTP_TEST_CAPTURED_HEADERS[http1]" "${summary_prefix}-headers-http1"

        run_test_http2 "$target_url" "${summary_prefix}-http2" "$insecure_mode"
        check_headers "$HTTP_TEST_CAPTURED_HEADERS[http2]" "${summary_prefix}-headers-http2"

        run_test_http3 "$target_url" "${summary_prefix}-http3" "$insecure_mode"
        if [[ -n "$HTTP_TEST_CAPTURED_HEADERS[http3]" ]]; then
            check_headers "$HTTP_TEST_CAPTURED_HEADERS[http3]" "${summary_prefix}-headers-http3"
        fi

        check_redirects "$target_url" "${summary_prefix}-redirects" "$insecure_mode"
        detect_cdn "$HTTP_TEST_CAPTURED_HEADERS[http2]$'\n'$HTTP_TEST_CAPTURED_HEADERS[http1]" "${summary_prefix}-cdn"

        if [[ "$target_scheme" == "https" ]]; then
            check_tls "$target_url" "${summary_prefix}-tls" "$insecure_mode"
        fi

        if (( HTTP_TEST_VERBOSE )); then
            if [[ -n "$HTTP_TEST_CAPTURED_HEADERS[http1]" ]]; then
                _http_test_print_section "Verbose HTTP/1.1 Headers"
                printf "%s\n" "$HTTP_TEST_CAPTURED_HEADERS[http1]"
            fi
            if [[ -n "$HTTP_TEST_CAPTURED_HEADERS[http2]" ]]; then
                _http_test_print_section "Verbose HTTP/2 Headers"
                printf "%s\n" "$HTTP_TEST_CAPTURED_HEADERS[http2]"
            fi
            if [[ -n "$HTTP_TEST_CAPTURED_VERBOSE[http2]" ]]; then
                _http_test_print_section "Verbose curl output"
                printf "%s\n" "$HTTP_TEST_CAPTURED_VERBOSE[http2]"
            fi
        fi
    done

    print_summary
    return $HTTP_TEST_EXIT_CODE
}

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

