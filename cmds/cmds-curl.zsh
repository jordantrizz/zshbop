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