# --
# Litespeed commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[litespeed]='Litespeed and Openlitespeed commands'

# - Init help array
typeset -gA help_litespeed

# - lsw-restart
help_litespeed[lsws-fullrestart]='Restart LSW/OLS and kill lsphp'
lsw-fullrestart () {
	lswsctrl fullrestart
	skill -9 lsphp
}

# - lsws
help_litespeed[lsws]='Change directory to Litespeed root'
lsws () {
	cd /usr/local/lsws
}

# - lsphp74
help_litespeed[lsphp74]='Run lsphp74 cli'
alias lsphp74="/usr/local/lsws/lsphp74/bin/php"

help_litespeed[lsphp81]='Run lsphp81 cli'
alias lsphp81="/usr/local/lsws/lsphp81/bin/php"
