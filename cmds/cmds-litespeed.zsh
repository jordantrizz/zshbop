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