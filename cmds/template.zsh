# --
# template commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[template_description]="Malware scanning software and commands"
help_files[template]='Malware scanning'

# - Init help array
typeset -gA help_template

_debug " -- Loading ${(%):-%N}"

# -- paths
help_template[test]='print out \$PATH on new lines'
test () {
	echo ${PATH:gs/:/\\n}
}