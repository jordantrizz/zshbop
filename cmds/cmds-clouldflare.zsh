# --
# cloudflare commands
#
# Example help: help_cloudflare[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_cloudflare

# What help file is this?
help_files[cloudflare_description]="Cloudflare commands"
help_files[cloudflare]='Cloudflare Commands'

# -- cfpurge
help_cloudflare[cfpurge]='Purge single or multiple urls'

# -- cloudflare
help_cloudflare[cloudflare]='The bash cloudflare cli'
alias cf="cloudflare"