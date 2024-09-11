# ==============================================================================
# npm software
# ==============================================================================

# ===============================================
# -- _check_npm
# ===============================================
function _check_npm () {
    _cmd_exists npm
    if [[ $? == "1" ]]; then
        _error "npm not installed, npm reqired."
        return 1
    fi
}

# ===============================================
# -- gnomon
# ===============================================
help_software[gnomon]='Gnomon prepends timestamp information to the standard output of another command'
function software_gnomon () {
    _check_npm
    [[ $(_check_npm) == "1" ]] && return 1
    npm install -g gnomon
}