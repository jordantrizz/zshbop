# -----------------------------
# -- functions-core.zsh
# --
# -- Core functions for scripts
# -----------------------------
_debug "Loading core functions for scripts functions-core.zsh"

###############################

# --------------------
# -- help_corefunc array
# --------------------
typeset -gA help_corefunc
help_files[corefunc]='Core functions for scripts'

# ---------------------------------------------------------------
# -- _require_pkg ($package)
# --
# -- Check to see if command exists and if not install
# ---------------------------------------------------------------
help_corefunc[_require_pkg]='Check if command exists and if not install using package manager'
_require_pkg () {
        _debug_function
        _debug "Running _requires_pkg on $1"
        _debug "array: ${(P)${array_name}}"

                local array_name=$1
        PKG=""

        for PKG in ${(P)${array_name}}; do
        if [[ $(dpkg-query -W -f='${Status}' nano 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
                        if [[ $ZSH_DEBUG == 1 ]]; then
                                _debug "$PKG is installed";
                                REQUIRES_PKG=0
                        fi
                else
                        if [[ $ZSH_DEBUG == 1 ]]; then
                                _debug "$PKG not installed";
                        fi
                        echo "$PKG not installed, installing"
                        sudo apt-get install $PKG
                        REQUIRES_PKG=1
                fi
        done

}

# ----------------------------------------
# -- _requires_cmd ($command)
# --
# -- Check to see if $command is installed
# ----------------------------------------
_requires_cmd () {
    _debug_function
    _debug "Running _requires on $1"
    _debug "array: ${(P)${array_name}}"

    local array_name=$1
    CMD=""

    for CMD in ${(P)${array_name}}; do
            if (( $+commands[$CMD] )); then
            _debug $(which $CMD)
                    if [[ $ZSH_DEBUG == 1 ]]; then
                            _debug "$CMD is installed";
                            REQUIRES_CMD=0
                    fi
            else
                    if [[ $ZSH_DEBUG == 1 ]]; then
                            _debug "$CMD not installed";
                    fi
                    echo "$CMD not installed"
                    REQUIRES_CMD=1
            fi
        done
}

# ------------------------------------------------------------------------
# -- _cexists
# --
# -- Returns 0 if command exists or 1 if command doesn't exist
# ------------------------------------------------------------------------
_cexists () {
    unset CMD_EXISTS CMD CMD_PATH
    CMD="$1"

    # Check if command exists
    CE_PATH=$(which $CMD)
    CE_EXIT_CODE=$?
    if [[ $CE_EXIT_CODE == "0" ]]; then
        CMD_PATH=$(which $CMD)
        _debug "CMD_PATH: $CMD_PATH"
        if [[ $ZSH_DEBUG == 1 ]]; then
            _debug "$CMD is installed";
        fi
            CMD_EXISTS="0"
    else
        if [[ $ZSH_DEBUG == 1 ]]; then
            _debug "$CMD not installed";
        fi
            CMD_EXISTS="1"
    fi

    # Check if alias exists
    return $CMD_EXISTS
}

# ---------------------------------------
# -- checkroot()
# --
# -- checkroot - check if running as root
# ---------------------------------------
_checkroot () {
        _debug_function
    if [[ $EUID -ne 0 ]]; then
        _error "Requires root...exiting."
    return
    fi
}

# ------------------------------------------------------
# -- _if_marray - if in array.
# -- _if_marray "$NEEDLE" HAYSTACK
# -- must use quotes, second argument is array without $
# ------------------------------------------------------
_if_marray () {
    _debug_function
        MARRAY_VALID=1
        _debug "$funcstack[1] - find value = $1 in array = $2"
        for value in ${(k)${(P)2[@]}}; do
                _debug "$funcstack[2] - array=$2 \$value = $value"
                if [[ $value == "$1" ]]; then
                        _debug "$funcstack[1] - array $2 does contain $1"
                        MARRAY_VALID="0"
                else
                        _debug "$funcstack[1] - array $2 doesn't contain $1"
                fi
        done
        _debug "MARRAY_VALID = $MARRAY_VALID"
        if [[ MARRAY_VALID == "1" ]]; return 0
}

# ---------------
# -- _lines2array
# ---------------
_lines2array() {
  local IFS=$'\n\n' ret
  array_of_lines=($("$@"; ret=$?; echo .; exit $ret))
  ret=$?
  unset 'array_of_lines[-1]'
  return $ret
}