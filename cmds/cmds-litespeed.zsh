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
help_litespeed[lsw-restart]='Restart LSW/OLS and kill lsphp'
lsw-restart () {
	systemctl restart lsws
	killall lsphp
}
