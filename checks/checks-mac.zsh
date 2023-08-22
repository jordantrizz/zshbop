#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- mac-checks.zsh -- Checks for macOS
# -----------------------------------------------------------------------------------
_debug " -- Loading ${(%):-%N}"

# -- mac-checks
help_checks[mac-checks]='Run all checks for macOS'
function mac-checks () {
    # Loop through help_checks_mac and run each function
    for func in ${(k)help_checks}; do
        if [[ $string == "mac-check-"* ]]; then
            $func
        fi
    done
}

# -- mac-check-brew () - Checks if brew is installed
help_checks[mac-check-brew]='Checks if brew is installed'
function mac-check-brew () {
    if ! command -v brew > /dev/null; then
        _notice "brew is not installed."
        return 1
    fi
    return 0
}

# -- mac-check-bash () - Checks if the current version of bash is above 4.0
help_checks[mac-check-bash]='Checks if the current version of bash is above 4.0'
function mac-check-bash () {
    # -- Run bash --version to check output
    BASH_VERSION_CLI=$(bash --version | head -n1 | awk '{print $4}')
    if [[ $BASH_VERSION_CLI < 4.0 ]]; then
        _error "Bash version is too old. Please upgrade to 4.0 or higher."
        return 1
    fi
    return 0    
}