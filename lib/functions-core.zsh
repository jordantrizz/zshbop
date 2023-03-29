# -----------------------------
# -- functions-core.zsh
# --
# -- Core functions for scripts
# -----------------------------

# -- Help category
typeset -gA help_files
typeset -gA help_corefunc
help_files[corefunc]='Core functions for scripts'

# ---------------------
# -- Internal Functions
# ---------------------

# -- Different colored messages
_echo () { echo "$@" }
_error () { echo  "$fg[red] * $@ ${RSC}" }
_warning () { echo "$fg[yellow] * $@ ${RSC}" }
_success () { echo "$fg[green] * $@ ${RSC}" }
_noticebg () { echo "$bg[magenta]$fg[white] * $@ ${RSC}" }
_noticefg () { echo "$fg[magenta] * $@ ${RSC}" }
alias _notice="_noticefg"

# -- Banners
_banner_red () { echo "$bg[red]$fg[white]${@}${RSC}" }
_banner_green () { echo "$bg[green]$fg[white]${@}${RSC}" }
_banner_yellow () { echo "$bg[yellow]$fg[black]${@}${RSC}" }
_banner_grey () { echo "$bg[bright-grey]$fg[black]${@}${RSC}" }
_loading () { echo "$bg[yellow]$fg[black] * ${@}${RSC}" }
_loading2 () { echo "$bg[bright-grey]$fg[black]${@}${RSC}" }
_loading3 () { echo "$bg[bright-grey]$fg[black]${@}${RSC}" }
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

# ------------
# -- Debugging
# ------------
ZSH_DEBUG="0"

# -- zshbop debugging
if [ -f $ZSHBOP_ROOT/.debug ]; then
        export ZSH_DEBUG=1
elif [ ! -f $ZSHBOP_ROOT/.debug ]; then
        export ZSH_DEBUG=0
fi

# -- _debug
_debug () {
    if [[ $ZSH_DEBUG == 1 ]]; then
        echo "$fg[cyan]** DEBUG: $@${RSC}";
    fi
}

# -- _debug_all
_debug_all () {
        _debug "--------------------------"
        _debug "arguments - $@"
        _debug "funcstack - $funcstack"
        _debug "ZSH_ARGZERO - $ZSH_ARGZERO"
        _debug "SCRIPT_DIR - $SCRIPT_DIR"
        _debug "--------------------------"
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

