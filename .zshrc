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
init_zshbop