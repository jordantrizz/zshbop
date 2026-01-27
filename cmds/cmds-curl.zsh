# --
# curl commands
#
# Example help: help_curl[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
help_files[curl]='Curl related commands'
typeset -gA help_curl

# ------------
# -- Functions
# ------------
alias vh-curl="curl-vh"
alias curl-vh="curl-vh.sh"
help_curl[curlh]="Use GET to show headers"
alias curlh="curl -sD - -o /dev/null $1"

# -- curll
help_curl[curll]="Use curl to get Location headers and follow redirects"
function curll () {
    curl -s -L -I $1 | grep -i 'Location'
}

# -----------------------------------------------
# -- curl-redirect
# -----------------------------------------------
help_curl[curl-redirect]="Use curl to get Location headers and follow redirects"
function curl-redirect () {
    curl -s -L -I $1 | grep -i 'Location'
}

# -----------------------------------------------
# -- curl-ua
# -----------------------------------------------
help_curl[curl-ua]="Use curl with a selected user agent"
function curl-ua() {
    # Define a list of user agents
    local user_agents=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
    )

    # Use fzf to select a user agent
    local selected_ua=$(printf "%s\n" "${user_agents[@]}" | fzf --prompt="Select a User-Agent: ")

    # Check if a user agent was selected
    if [[ -n "$selected_ua" ]]; then
        # Use the selected user agent with curl
        curl -A "$selected_ua" "$@"
    else
        echo "No User-Agent selected."
    fi
}

# ==================================================
# -- web-cache-control
# ==================================================
help_curl[web-cache-control]="Analyze HTTP caching headers for a URL"
function web-cache-control () {
    local url headers
    local cache_control expires etag last_modified age vary pragma
    local cf_cache_status x_cache x_cache_hits cdn_cache_control
    local max_age s_maxage stale_while_revalidate stale_if_error
    local date_header current_time remaining_ttl
    typeset -A detected_directives

    # -- Parse arguments using zparseopts
    zparseopts -D -E -- \
        {h,-help}=flag_help \
        {L,-follow}=flag_follow \
        {r,-raw}=flag_raw

    # -- Usage function
    function _web_cache_control_usage () {
        echo ""
        echo "Usage: web-cache-control [options] <url>"
        echo "  -h, --help     Show this help message"
        echo "  -L, --follow   Follow redirects to final URL"
        echo "  -r, --raw      Show raw headers only"
        echo ""
        echo "Example: web-cache-control https://example.com/style.css"
        echo ""
        echo "Analyzes HTTP headers related to caching:"
        echo "  - cache-control (max-age, s-maxage, public/private, etc.)"
        echo "  - expires, last-modified, etag, age, vary, pragma"
        echo "  - CDN headers (cf-cache-status, x-cache, etc.)"
    }

    # -- Show help
    if [[ -n "$flag_help" ]]; then
        _web_cache_control_usage
        return 0
    fi

    # -- Get URL from remaining arguments
    url="$1"

    # -- Validate URL
    if [[ -z "$url" ]]; then
        _error "Please provide a URL"
        _web_cache_control_usage
        return 1
    fi

    # -- Build curl command
    local curl_opts="-sI"
    if [[ -n "$flag_follow" ]]; then
        curl_opts="-sIL"
    fi

    _loading3 "Fetching headers for: $url"
    echo ""

    # -- Fetch headers
    headers=$(curl $curl_opts "$url" 2>/dev/null)
    if [[ $? -ne 0 ]] || [[ -z "$headers" ]]; then
        _error "Failed to fetch headers from $url"
        return 1
    fi

    # -- Raw output mode
    if [[ -n "$flag_raw" ]]; then
        echo "$headers"
        return 0
    fi

    # -- Extract headers (case-insensitive)
    cache_control=$(echo "$headers" | grep -i '^cache-control:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')
    expires=$(echo "$headers" | grep -i '^expires:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')
    etag=$(echo "$headers" | grep -i '^etag:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')
    last_modified=$(echo "$headers" | grep -i '^last-modified:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')
    age=$(echo "$headers" | grep -i '^age:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')
    vary=$(echo "$headers" | grep -i '^vary:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')
    pragma=$(echo "$headers" | grep -i '^pragma:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')
    date_header=$(echo "$headers" | grep -i '^date:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')

    # -- CDN-specific headers
    cf_cache_status=$(echo "$headers" | grep -i '^cf-cache-status:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')
    x_cache=$(echo "$headers" | grep -i '^x-cache:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')
    x_cache_hits=$(echo "$headers" | grep -i '^x-cache-hits:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')
    cdn_cache_control=$(echo "$headers" | grep -i '^cdn-cache-control:' | tail -1 | sed 's/^[^:]*: *//' | tr -d '\r')

    # -- Parse cache-control directives
    if [[ -n "$cache_control" ]]; then
        max_age=$(echo "$cache_control" | grep -oE 'max-age=[0-9]+' | cut -d= -f2)
        s_maxage=$(echo "$cache_control" | grep -oE 's-maxage=[0-9]+' | cut -d= -f2)
        stale_while_revalidate=$(echo "$cache_control" | grep -oE 'stale-while-revalidate=[0-9]+' | cut -d= -f2)
        stale_if_error=$(echo "$cache_control" | grep -oE 'stale-if-error=[0-9]+' | cut -d= -f2)
    fi

    # -- Helper function to format seconds as human readable
    function _format_duration () {
        local seconds="$1"
        local days hours mins secs result
        days=$((seconds / 86400))
        hours=$(( (seconds % 86400) / 3600 ))
        mins=$(( (seconds % 3600) / 60 ))
        secs=$((seconds % 60))
        result=""
        (( days > 0 )) && result+="${days}d "
        (( hours > 0 )) && result+="${hours}h "
        (( mins > 0 )) && result+="${mins}m "
        if (( secs > 0 )) || [[ -z "$result" ]]; then
            result+="${secs}s"
        fi
        echo "$result"
    }

    # ==================================================
    # -- Display Results
    # ==================================================

    _loading "Cache-Control Header"
    if [[ -n "$cache_control" ]]; then
        echo "  Raw: $cache_control"
        echo ""

        # -- Visibility
        if [[ "$cache_control" == *"public"* ]]; then
            echo "  ✓ public"
            detected_directives[public]=1
        elif [[ "$cache_control" == *"private"* ]]; then
            echo "  ⚠ private"
            detected_directives[private]=1
        fi

        # -- max-age
        if [[ -n "$max_age" ]]; then
            echo "  ✓ max-age: ${max_age}s ($(_format_duration $max_age))"
            detected_directives[max-age]=1
        fi

        # -- s-maxage (CDN/proxy specific)
        if [[ -n "$s_maxage" ]]; then
            echo "  ✓ s-maxage: ${s_maxage}s ($(_format_duration $s_maxage))"
            detected_directives[s-maxage]=1
        fi

        # -- stale-while-revalidate
        if [[ -n "$stale_while_revalidate" ]]; then
            echo "  ✓ stale-while-revalidate: ${stale_while_revalidate}s ($(_format_duration $stale_while_revalidate))"
            detected_directives[stale-while-revalidate]=1
        fi

        # -- stale-if-error
        if [[ -n "$stale_if_error" ]]; then
            echo "  ✓ stale-if-error: ${stale_if_error}s ($(_format_duration $stale_if_error))"
            detected_directives[stale-if-error]=1
        fi

        # -- no-cache / no-store / must-revalidate / proxy-revalidate
        if [[ "$cache_control" == *"no-store"* ]]; then
            echo "  ✗ no-store"
            detected_directives[no-store]=1
        fi
        if [[ "$cache_control" == *"no-cache"* ]]; then
            echo "  ⚠ no-cache"
            detected_directives[no-cache]=1
        fi
        if [[ "$cache_control" == *"must-revalidate"* ]]; then
            echo "  ⚠ must-revalidate"
            detected_directives[must-revalidate]=1
        fi
        if [[ "$cache_control" == *"proxy-revalidate"* ]]; then
            echo "  ⚠ proxy-revalidate"
            detected_directives[proxy-revalidate]=1
        fi
        if [[ "$cache_control" == *"immutable"* ]]; then
            echo "  ✓ immutable"
            detected_directives[immutable]=1
        fi

        # -- Legend for detected directives
        if [[ ${#detected_directives[@]} -gt 0 ]]; then
            echo ""
            _loading3 "Directive Legend"
            [[ -n "${detected_directives[public]}" ]] && echo "  public               - Response can be cached by any cache (browser, CDN, proxy)"
            [[ -n "${detected_directives[private]}" ]] && echo "  private              - Response can only be cached by the browser, not shared caches"
            [[ -n "${detected_directives[no-cache]}" ]] && echo "  no-cache             - Cache must revalidate with origin server before serving cached content"
            [[ -n "${detected_directives[no-store]}" ]] && echo "  no-store             - Response must not be stored in any cache whatsoever"
            [[ -n "${detected_directives[max-age]}" ]] && echo "  max-age=<seconds>    - Maximum time in seconds the response is considered fresh"
            [[ -n "${detected_directives[s-maxage]}" ]] && echo "  s-maxage=<seconds>   - Like max-age but only applies to shared caches (CDN/proxy)"
            [[ -n "${detected_directives[must-revalidate]}" ]] && echo "  must-revalidate      - Once stale, cache must not use response without successful revalidation"
            [[ -n "${detected_directives[proxy-revalidate]}" ]] && echo "  proxy-revalidate     - Like must-revalidate but only for shared caches (CDN/proxy)"
            [[ -n "${detected_directives[immutable]}" ]] && echo "  immutable            - Response body will never change; browser can skip revalidation"
            [[ -n "${detected_directives[stale-while-revalidate]}" ]] && echo "  stale-while-revalidate=<seconds> - Serve stale content while fetching fresh copy in background"
            [[ -n "${detected_directives[stale-if-error]}" ]] && echo "  stale-if-error=<seconds>         - Serve stale content if origin server returns an error"
        fi
    else
        echo "  (not set)"
    fi
    echo ""

    # -- Calculate TTL
    _loading2 "Cache TTL Analysis"
    if [[ -n "$max_age" ]]; then
        if [[ -n "$age" ]]; then
            remaining_ttl=$((max_age - age))
            if (( remaining_ttl > 0 )); then
                echo "  max-age: ${max_age}s, age: ${age}s"
                echo "  ✓ Remaining TTL: ${remaining_ttl}s ($(_format_duration $remaining_ttl))"
            else
                echo "  max-age: ${max_age}s, age: ${age}s"
                echo "  ✗ Cache EXPIRED: $((-remaining_ttl))s ago"
            fi
        else
            echo "  max-age: ${max_age}s ($(_format_duration $max_age))"
            echo "  (age header not present - cannot calculate remaining TTL)"
        fi
    else
        echo "  (no max-age directive)"
    fi
    echo ""

    # -- Validation Headers
    _loading "Validation Headers (Conditional Requests)"
    if [[ -n "$etag" ]]; then
        echo "  ETag: $etag"
        if [[ "$etag" == W/* ]]; then
            echo "    → Weak validator (content semantically equivalent)"
        else
            echo "    → Strong validator (byte-for-byte identical)"
        fi
    else
        echo "  ETag: (not set)"
    fi

    if [[ -n "$last_modified" ]]; then
        echo "  Last-Modified: $last_modified"
    else
        echo "  Last-Modified: (not set)"
    fi
    echo ""

    # -- CDN Status
    _loading "CDN/Proxy Cache Status"
    if [[ -n "$cf_cache_status" ]]; then
        echo "  Cloudflare (cf-cache-status): $cf_cache_status"
        case "$cf_cache_status" in
            HIT)     echo "    → Served from Cloudflare cache" ;;
            MISS)    echo "    → Not in cache, fetched from origin" ;;
            EXPIRED) echo "    → Was cached but expired, fetched fresh" ;;
            STALE)   echo "    → Serving stale content while revalidating" ;;
            BYPASS)  echo "    → Cache bypassed (check cache rules)" ;;
            DYNAMIC) echo "    → Not cached (dynamic content)" ;;
            REVALIDATED) echo "    → Cache revalidated with origin" ;;
        esac
    fi

    if [[ -n "$x_cache" ]]; then
        echo "  X-Cache: $x_cache"
    fi

    if [[ -n "$x_cache_hits" ]]; then
        echo "  X-Cache-Hits: $x_cache_hits"
    fi

    if [[ -z "$cf_cache_status" && -z "$x_cache" && -z "$x_cache_hits" ]]; then
        echo "  (no CDN cache headers detected)"
    fi
    echo ""

    # -- Other Cache Headers
    _loading "Other Cache-Related Headers"
    if [[ -n "$expires" ]]; then
        echo "  Expires: $expires"
        echo "    → Legacy header, cache-control max-age takes precedence"
    fi

    if [[ -n "$pragma" ]]; then
        echo "  Pragma: $pragma"
        echo "    → Legacy HTTP/1.0 header"
    fi

    if [[ -n "$vary" ]]; then
        echo "  Vary: $vary"
        echo "    → Cache varies by these request headers"
    fi

    if [[ -n "$age" ]]; then
        echo "  Age: ${age}s ($(_format_duration $age))"
        echo "    → Time since cached by proxy/CDN"
    fi

    if [[ -n "$cdn_cache_control" ]]; then
        echo "  CDN-Cache-Control: $cdn_cache_control"
        echo "    → CDN-specific cache directives"
    fi

    if [[ -z "$expires" && -z "$pragma" && -z "$vary" && -z "$age" && -z "$cdn_cache_control" ]]; then
        echo "  (none detected)"
    fi
    echo ""

    # -- Server date
    if [[ -n "$date_header" ]]; then
        _loading "Server Time"
        echo "  Date: $date_header"
    fi
}