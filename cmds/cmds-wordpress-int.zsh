# =========================================================
# -- WordPress
# =========================================================
_debug " -- Loading ${(%):-%N}"
help_files[wordpress]='WordPress related commands'
typeset -gA help_wordpress
help_int[wordpress_func]='WordPress internal functions'
typeset -gA help_int_wordpress

# =========================================================
# -- _wp-cli-check
# =========================================================
# Check if wp-cli is installed
# Usage: _wp-cli-check
help_int_wordpress[_wp-cli-check]='Check if wp-cli is installed'
_wp-cli-check () {
        # Check if wp-cli is installed
        _cmd_exists wp
        if [[ $? == "1" ]]; then
                _error "Can't find wp-cli:"
                return 1
        fi
}

# =========================================================
# -- _wp-install-check
# =========================================================
# Check if WordPress is installed
# Usage: _wp-install-check
help_int_wordpress[_wp-install-check]='Check if WordPress is installed'
_wp-install-check () {
    local OUTPUT_DIR=$1 WP_EXISTS CWD=$(pwd)
    # Check if WordPress is installed
    WP_EXISTS="$(wp core is-installed --path='${CWD}' 2> /dev/null)"
    if [[ $? == 1 ]]; then
            _error "WordPress is not installed in the current directory."
            return 1
    else
        if [[ -n $OUTPUT_DIR ]]; then
            echo "$CWD"
        fi
    fi
}