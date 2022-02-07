# - Set the ZDOTDIR to $HOME this fixes system wide installs not being able to generate .zwc files for caching
ZDOTDIR=$HOME

# - We use $ZSH_ROOT to know our working directory.
# - This is to migrate to $ZSHBOP_ROOT from $ZSH_ROOT
if [ ! -z "$ZSH_ROOT" ]; then
	ZSHBOP_ROOT=$ZSH_ROOT
fi

if [ -z "$ZSHBOP_ROOT" ]; then
        _debug "-- \$ZSHBOP_ROOT empty so using \$HOME/zsh"
        export ZSH_ROOT=$HOME/$SCRIPT_NAME
else
        _debug "-- \$ZSHBOP_ROOT not empty so using $ZSHBOP_ROOT"
fi

# - Initilize zshbop
source $ZSH_ROOT/zshbop.zshrc

# - Set umask
umask 022
