# ---------------------------
# -- DO NOT MODIFY THIS FILE.
# ---------------------------
#
# If you need to set specific overrides, then create a file in $HOME/.zshbop and add overrides.
#
if [[ -f $HOME/.zshbop ]]; then
	source $HOME/.zshbop
fi

# -- Set the ZDOTDIR to $HOME this fixes system wide installs not being able to generate .zwc files for caching
ZDOTDIR=$HOME

#- Detecting where zshbop might be installed
if [ -z "$ZSHBOP_ROOT" ]; then
	_debug "\$ZSHBOP_ROOT empty so running detection"
	if [ -f $HOME/zshbop/zshbop.zshrc ]; then 
		export ZSHBOP_ROOT=$HOME/zshbop;
        	echo "---- Loading from $ZSHBOP_ROOT"
	elif [ -f $HOME/git/zshbop/zshbop.zshrc ]; then 
		export ZSHBOP_ROOT=$HOME/git/zshbop;
	        echo "---- Loading from $ZSHBOP_ROOT"
	elif [ -f /usr/local/sbin/zshbop/zshbop.zshrc ]; then
        	export ZSH_ROOT=/usr/local/sbin/zshbop;fi
	        echo "---- Loading from $ZSH_ROOT"
        fi
fi

# - Initilize zshbop
source $ZSH_ROOT/zshbop.zshrc
