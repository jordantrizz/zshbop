# --------------
# -- Functions
# --------------
# This file contains all the required functions for the main .zshrc script.

# -----------------------
# -- One line functions
# -----------------------

# -- placehodler for echo
_echo () { echo "$@" }

# -- debugging
_debug () { if [[ $ZSH_DEBUG == 1 ]]; then echo "** DEBUG: $@"; fi }

#-- Check to see if command exists and then return true or false
_cexists () {
        if (( $+commands[$@] )); then
                if [[ $ZSH_DEBUG == 1 ]]; then
                        _debug "$@ is installed";
                fi
                return 0
        else
                if [[ $ZSH_DEBUG == 1 ]]; then
                        _debug "$@ not installed";
                fi
                return 1
        fi
}
