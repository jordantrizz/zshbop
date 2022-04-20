# --
# Core commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
#
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[core]='Core commands'

# - Init help array
typeset -gA help_core

_debug " -- Loading ${(%):-%N}"


# -- paths
help_core[paths]='print out \$PATH on new lines'
paths () {
	echo ${PATH:gs/:/\\n}
}