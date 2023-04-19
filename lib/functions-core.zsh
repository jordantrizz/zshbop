#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- functions-core.zsh -- Core functions for scripts
# -----------------------------------------------------------------------------------
_debug_load

# -- Help category
typeset -gA help_files
typeset -gA help_corefunc
help_files[corefunc]='Core functions for scripts'

# ---------------------
# -- Internal Functions
# ---------------------

# -- Banners
_echo () { echo "$@" }
_success () { echo "$fg[green] * $@ ${RSC}" }
_noticebg () { echo "$bg[magenta]$fg[white] * $@ ${RSC}" }
_noticefg () { echo "$fg[magenta] * $@ ${RSC}" }
alias _notice="_noticefg"
_banner_red () { echo "$bg[red]$fg[white]${@}${RSC}" }
_banner_green () { echo "$bg[green]$fg[white]${@}${RSC}" }
_banner_yellow () { echo "$bg[yellow]$fg[black]${@}${RSC}" }
_banner_grey () { echo "$bg[bright-grey]$fg[black]${@}${RSC}" }
_loading () { echo "$bg[yellow]$fg[black] * ${@}${RSC}" }
_loading2 () { echo " $bg[bright-grey]$fg[black] * ${@}${RSC}" }
_loading3 () { echo "$fg[bright-grey]${@}${RSC}" }
_loading4 () { echo "$fg[bright-grey]${@}${RSC}" }
alias _loading_grey=_loading2

COLOR_FUNCTIONS=(_error _warning _success _noticebg _noticefg _banner_red _banner_green  _banner_grey _loading _loading2 _loading3 _loading4)

# -- Text Colors
_grey () { echo "$bg[bright-gray]$fg[black] $@ ${RSC}" }
RSC=$reset_color # To replace $reset_color :)

function colors-print () {
  for k in ${(k)color}; do
    if [[ ! $k =~ ^(fg|bg|[[:digit:]]{1,3}|no-|none|normal|italic|underline|reverse|bold|conceal|faint|default|blink) ]]; then
        echo "${k}: ${fg[$k]} Foreground ${RSC} - ${bg[$k]}Background${RSC}"                  
    fi
  done
}

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
    unset CMD_EXISTS
    CMD="$1"

    # Check if command exists
    if (( $+commands[${CMD}] )); then
        _debug "$CMD is installed";
        CMD_EXISTS="0"
    else
        _debug "$CMD not installed";    
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

# --------------------------------
# -- _pipe_separate
# --
# -- Separate piped output into columns after third item
# --------------------------------
function _pipe_separate() {
    local -a lines=("${(f)$(cat)}")
    local -i count=0
    [[ ${1} ]] && local ITEMS=$1 || local ITEMS=3

    for line in "${lines[@]}"; do
        if (( count < ${ITEMS} )); then
        printf "%s | " "$line"
        (( count++ ))
        else
        printf "%s\n" "$line"
        count=0
        fi
    done
    echo ""
}

