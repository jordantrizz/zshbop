# --
# Nginx commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[nginx]='Nginx related commands'

# - Init help array
typeset -gA help_nginx

# -- nginx-inc
help_nginx[nginx-inc]='List all fins included in nginx.conf, I think?' 
nginx-inc () { 
	cat $1; grep '^.*[^#]include' $1 | awk {'print $2'} | sed 's/;\+$//' | xargs cat 
}

# -- nginx-404log
help_nginx[nginx-404log]='List top 404 pages in an Nginx access log, with GridPane support'
alias nginx-404log="$ZSH_ROOT/bin/nginx-404log.sh"
