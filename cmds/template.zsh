# --
# replace commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[replace]="Malware scanning software and commands"

# - Init help array
typeset -gA help_replace

_debug " -- Loading ${(%):-%N}"

# -- paths
help_replace[test]='print out \$PATH on new lines'
test () {
	echo ${PATH:gs/:/\\n}
}