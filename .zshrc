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

# -- Potential zshbop paths, including old zsh path
ZSHBOP_PATHS=("$HOME/zshbop" "$HOME/zsh" "$HOME/git/zshbop" "$HOME/git/zsh" "/usr/local/sbin/zshbop" "/usr/local/sbin/zsh")

# -- Detecting where zshbop might be installed
if [ -z "$ZSHBOP_ROOT" ]; then
	for ZBPATH in "${ZSHBOP_PATHS[@]}"; do
		if [[ -f "$ZBPATH/zshbop.zsh" ]]; then
			export ZSHBOP_ROOT=$ZBPATH;
	                echo "-- Loading from $ZSHBOP_ROOT"
		fi
	done
	if [ -z "$ZSHBOP_ROOT" ]; then
		echo "-- Can't locate zshbop, we broken dude :("
		return
	fi
fi

# - Initilize zshbop
echo "-- Initilizing zshbop"
source $ZSHBOP_ROOT/zshbop.zsh
