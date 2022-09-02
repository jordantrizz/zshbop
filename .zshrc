# ---------------------------
# -- DO NOT MODIFY THIS FILE.
# ---------------------------

# -- Potential zshbop paths, including old zsh path
ZSHBOP_PATHS=("$HOME/zshbop" "$HOME/zsh" "$HOME/git/zshbop" "$HOME/git/zsh" "/usr/local/sbin/zshbop" "/usr/local/sbin/zsh")

# -- Detecting where zshbop might be installed
if [ -z "$ZSHBOP_ROOT" ]; then
	for ZBPATH in "${ZSHBOP_PATHS[@]}"; do
		if [[ -f "$ZBPATH/zshbop.zsh" ]]; then
			export ZSHBOP_ROOT=$ZBPATH;
	        echo "\e[43;30m-- Loading from $ZSHBOP_ROOT\e[0m"
	        break
		fi
	done
	if [ -z "$ZSHBOP_ROOT" ]; then
		echo "\e[41;30m-- Can't locate zshbop, we broken dude :(\e[0m"
		return
	fi
fi

# - Initilize zshbop
echo "\e[43;30m-- Initilizing zshbop \e[0m"
source $ZSHBOP_ROOT/zshbop.zsh
init_zshbop