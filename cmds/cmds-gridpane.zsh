# --
# template commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[gridpane_description]="Common GridPane Tools"
help_files[gridpane]="Common GridPane Tools"

# - Init help array
typeset -gA help_gridpane

_debug " -- Loading ${(%):-%N}"

# -- gridpane command
gridpane () {
	if [[ -z $@ ]] || [[ $1 == "help" ]]; then
        echo "Usage: gridpane <cmd>"
        help gridpane
        return 1
	else
        echo "Running ${1}"
        gridpane_${1} $@
    fi
}

# -- gph command
gph () {
    if [[ -z $@ ]]; then
        echo "Usage: gph <cmd>"
		help gridpane
        return 1
    else
        echo "Running ${1}"
        gridpane_${1} $@
    fi
}

# -- gph ssl-logs
help_gridpane[ssl-logs]='print out \$PATH on new lines'
gridpane_ssl-logs () {
    DOMAIN="$2"
    if [[ -z $DOMAIN ]]; then
        echo "Usage: ssl-logs <domain>"
        return 1
    else
        echo "Tailing 100 lines of /var/www/$DOMAIN/logs/ssl-provision.log"
        tail -n 100 /var/www/$DOMAIN/logs/ssl-provision.log | less
    fi
}

# -- gph certbot-logs
help_gridpane[certbot-logs]="Certbot and Acme logs"
gridpane_certbot-logs () {
	tail -n 100 /opt/gridpane/certbot.monitoring.log /opt/gridpane/acme.monitoring.log;echo "Tailing 100 lines of /opt/gridpane/certbot.monitoring.log & /opt/gridpane/acme.monitoring.log"
}