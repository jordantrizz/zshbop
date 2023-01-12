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
alias gpd="gridpane"
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

# -- gph check-fsl
help_gridpane[check-fsl]="Check duplicacy .fsl files"
check-fsl () { 
	echo "\n** Checking duplicacy storage **";
    echo "----"
	echo -n "Total size of backup chunks: ";du --max-depth=0 -h /opt/gridpane/backups/duplications/chunks
	echo "----"
	echo -n "Total .fsl files: ";find /opt/gridpane/backups/duplications/chunks -name "*.fsl" | wc -l
	echo -n "Total .fsl file size: ";find /opt/gridpane/backups/duplications/chunks -type f -name "*.fsl" -print0 | du --files0-from=- -hc | tail -n1
	echo "----"
	echo -n "Total normal chunk files: "; find /opt/gridpane/backups/duplications/chunks -type f ! -name "*.fsl" | wc -l; \
	echo -n "Total normal chunk file size: "; find /opt/gridpane/backups/duplications/chunks -type f ! -name "*.fsl" -print0 | du --files0-from=- -hc | tail -n1; \
    echo "----"
	echo -n "Duplicacy reporting totals: "
	REPOSITORY=$(dirname "$(find /var/www/ -name ".duplicacy" | tail -n 1)")
	cd $REPOSITORY >> /dev/null
	duplicacy check -tabular | grep Total
}

# -- gp-mysql
help_gridpane[gp-mysql]="Gridpane MYSQL command"
gp-mysql () {
	mysqlrootpw=$(grep -oP '^mysql-root:\K.*' /root/gridenv/promethean.env | openssl enc -d -a -salt);
	mysql --user root --password="${mysqlrootpw}"
}

# -- gp-mysqltuner.pl
help_gridpane[gp-mysqltuner.pl]="GridPane mysqltuner.pl command"
gp-mysqltuner.pl () {
	mysqlrootpw=$(grep -oP '^mysql-root:\K.*' /root/gridenv/promethean.env | openssl enc -d -a -salt);
	mysqltuner.pl --user root --pass $mysqlrootpw
}

# -- gp-mysqlpass
help_gridpane[gp-mysqlpass]="Get GridPane root MySQL Password"
gp-mysqlpass () {
	grep -oP '^mysql-root:\K.*' /root/gridenv/promethean.env | openssl enc -d -a -salt
}

# -- gp-duplicacy-audit
help_gridpane[gp-duplicacy-audit]="Audit Duplicacy backups"
gp-duplicacy-audit () {
    duplicacy check -tabular | grep 'all' | awk {' print $1 " "$10 '} | sed 's/gridpane-[[:alnum:]]*-[[:alnum:]]*-[[:alnum:]]*-[[:alnum:]]*-[[:alnum:]]*-//' | column -t
}

# gp-logs
help_gridpane[gp-logs]="Tail GridPane Logs"
gp-logs () {
	gridpane_logs=("/var/log/gridpane.log" "/var/log/monit.log" "/usr/local/maldetect/logs/event_log" "/var/log/mysql/error.log")
	if [[ -z $1 ]]; then
		_error "usage: gp-logs <# of lines>"
		lines="20"
	else
		lines="${1}"
		for log in $gridpane_logs; do
			if [[ -f $log ]]; then
				_notice "---- tail -n ${lines} ${log}"
				tail -n ${1} ${log}
			else
				_error "Can't find $log"
			fi				
		done
	fi
}

# -- gp-motd
help_gridpane[gp-motd]="GridPane MOTD"
gp-motd () {
    # -- monit logs, grab last 10 warnings and errors
    egrep -i ' warning | error ' /var/log/monit.log | tail -10
    
    # -- inform
    _notice "View more GridPane logs with the command gp-logs"
}

# -- gp-monit527
help_gridpane[gp-monit527]="Upgrade monit to 5.27 on aGridPane server"
gp-monit527 () {
    systemctl stop monit
    cd /opt/gridpane/
    wget https://mmonit.com/monit/dist/binary/5.27.0/monit-5.27.0-linux-x64.tar.gz
    tar zxvf /opt/gridpane/monit-5.27.0-linux-x64.tar.gz
    rm /opt/gridpane/monit-5.27.0-linux-x64.tar.gz
    cp /opt/gridpane/monit-5.27.0/bin/monit /usr/local/bin/
    systemctl start monit
    tail -20 /var/log/monit.log
}
