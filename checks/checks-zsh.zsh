#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- checks-vm -- Checks for VM
# -----------------------------------------------------------------------------------
_debug " -- Loading ${(%):-%N}"

# -- vm-checks
help_checks[zsh-checks]='Run all checks for VM'
function zsh-checks () {
    # Loop through help_checks and run each function
    for func in ${(k)help_checks}; do
        if [[ $string == "zsh-check-"* ]]; then
            $func
        fi
    done
}

# ==============================================
# -- check zsh version
# ==============================================
help_checks[zsh-check-version]='Check zsh version'
function zsh-check-version () {
	# -- Check zsh version - https://scriptingosx.com/2019/11/comparing-version-strings-in-zsh/
	_log "Running ZSH $ZSH_VERSION - Latest version is 5.9 as per https://zsh.sourceforge.io/News/"
	autoload is-at-least
	if ! is-at-least 5.7 $ZSH_VERSION; then
		_warning "Running older ZSH Version, please upgrade https://github.com/lmtca/zsh-installs"
	else
    	_log "Running close to latest ZSH"
	fi
}

# ==============================================
# -- check zsh history configuration
# ==============================================
help_checks[zsh-check-history]='Check zsh history configuration'
function zsh-check-history () {
	_log "Checking zsh history configuration"
	echo "  HISTFILE: ${HISTFILE:-(unset)}"
	echo "  HISTSIZE: ${HISTSIZE:-(unset)}"
	echo "  SAVEHIST: ${SAVEHIST:-(unset)}"

	if [[ -n "$HISTFILE" && "$SAVEHIST" -gt 0 ]]; then
		_success "History is enabled, persisting to $HISTFILE"
		return 0
	fi

	_warning "History is disabled: HISTFILE is unset or SAVEHIST is 0"
	return 1
}