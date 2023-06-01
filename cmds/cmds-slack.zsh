# -- slack commands
_debug " -- Loading ${(%):-%N}"
help_files[slack]="Slack commands"
typeset -gA help_slack

# -- slacktee.sh
help_slack[slacktee.sh]='Send a message to slack via pipe'
