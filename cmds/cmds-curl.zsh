# --
# curl commands
#
# Example help: help_curl[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
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