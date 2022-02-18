# --
# dns commands
#
# Example help: help_dns[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_dns

# What help file is this?
help_files[dns]='DNS Commands'

# -- dnst
help_dns[dnst]='Run dnstracer on root name servers'
 
dnst () {
	if [ -x $1 ]; then echo "dnst <domain>";return; fi
	dnstracer -o -s b.root-servers.net -4 -r 1 $1	
}

