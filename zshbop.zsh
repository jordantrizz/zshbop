#!/usr/bin/env zsh
# ------------------------
# -- zshbop file
# -------------------------

# ---------
# -- Source
# ---------
source ${ZSHBOP_ROOT}/functions.zsh # -- 
source ${ZSHBOP_ROOT}/init.zsh # -- include init
source ${ZSHBOP_ROOT}/aliases.zsh # -- include functions
source ${ZSHBOP_ROOT}/help.zsh # -- include help functions
source ${ZSHBOP_ROOT}/kb.zsh # -- Built in Knolwedge Base
source ${ZSHBOP_ROOT}/colors.zsh # -- colors

# -------
# -- Main
# -------

# -- If you need to set specific configuration settings then create $HOME/.zshbop.config and look at zshbop.config.example
if [[ -f $HOME/.zshbop.config ]]; then
	source $HOME/.zshbop.config
fi

# -------------------------
# -- Check for old versions
# -------------------------
zshbop_previous-version-check
zshbop_migrate