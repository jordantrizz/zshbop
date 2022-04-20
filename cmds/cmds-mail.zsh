# --
# Mail commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[mail]='All mail related commands'

# - Init help array
typeset -gA help_mail

# -- eximcq
help_mail[eximcq]='Clear all mail in exim MTA queue. *DANGER*'
eximcq () { exim -bp | exiqgrep -i | xargs exim -Mrm }

# -- postmark
help_mail[postmark]='Postmark cli for sending email'
alias postmark="postmark.sh"