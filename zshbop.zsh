#!/usr/bin/env zsh
# =============================================================================
# -- zshbop.zsh -- zshbop main file
# -- 
# =============================================================================

# -- Reset init flag for new shell (prevents inheriting from parent)
# The guard in init_zshbop will still catch double-sourcing within same session
unset ZSHBOP_INITIALIZED

# -- Include
export ZSHBOP_ROOT=${0:a:h}
source ${ZSHBOP_ROOT}/lib/include.zsh

###########################################################
# --- Start zshbop
###########################################################
STARTLOG

# -- Check for old bits
zshbop_cleanup 1

###########################################################
###########################################################
# --- DON'T PUT ANYTHING BELOW THIS LINE ---
# -------------------------
# -- Initialize ZSHBOP
# -------------------------
init_zshbop

# -- Check if git-check-exit is set
_log "Checking if \$ZSHBOP_GIT_CHECK is set"
if [[ $ZSHBOP_GIT_CHECK == "1" ]]; then
    _log "Running git-check-exit on logout to check for git changes"
    trap "git-check-exit" EXIT
fi 

STOPLOG
