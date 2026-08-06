#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- checks-update.zsh -- Checks for zshbop updates
# -----------------------------------------------------------------------------------
_debug " -- Loading ${(%):-%N}"

# ==================================================
# -- update-checks () - Run all zshbop update checks
# ==================================================
help_checks[update-checks]='Run all checks for zshbop updates'
function update-checks () {
    zshbop-check-update "$@"
}

# ==================================================
# -- zshbop-check-update () - Check for zshbop updates
# -- Tags on main, commits on next-release
# -- Implementation lives in lib/update-check.zsh;
# -- registered here for help_checks discoverability.
# -- NOTE: only runs when invoked - never at boot (network).
# ==================================================
help_checks[zshbop-check-update]='Check for zshbop updates (tags on main, commits on next-release)'
