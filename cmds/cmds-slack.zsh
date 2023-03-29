# --
# slack commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[slack]="Malware scanning software and commands"

# - Init help array
typeset -gA help_slack

_debug " -- Loading ${(%):-%N}"

# -- paths
help_slack[slack-tee.sh]='Send a message to slack via pipe'
