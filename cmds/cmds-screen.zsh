# -- screens commands
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_screen

# -- Screen
_cmd_exists screen
if [[ $? == 0 ]]; then	
	# -- Default screen alias
	alias screen="screen -c $ZSHBOP_ROOT/.screenrc"	
	
	# -- screens
	help_screen[screens]='List screen sessions'	
	alias screens="screen -list"
	
	# -- scrl
	help_screen[scrl]='List screen sessions'
	alias scrl="screen -list"
	
	# -- scra
	help_screen[scra]='Attach to screen session'
	function scra {
		screen -rd "${1}"
	}

	# -- scrc
	help_screen[scrc]='Create screen session with a name'
	function scrc {
		screen -dmS ${1}
		screen -rd ${1}
	}
fi
