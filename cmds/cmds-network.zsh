# --
# template commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[network_description]="Network tools and built-in scripts."
help_files[network]='Network Tools'

# - Init help array
typeset -gA help_network

_debug " -- Loading ${(%):-%N}"

# -- paths
help_network[interfaces]='Print out network interfaces'
interfaces () {
	# see os-<ostype>.zsh for each specific interfaces cmd.
}