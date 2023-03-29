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

# -- gp-mysqlps
help_gridpane[gp-mysqlps]="Gridpane mysql 'show full processlist'"
gp-mysqlps () {
    mysqlrootpw=$(grep -oP '^mysql-root:\K.*' /root/gridenv/promethean.env | openssl enc -d -a -salt);
    mysql --user root --password="${mysqlrootpw}" -e "show full processlist"
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
alias gp-motd="motd_gp"

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

# -- gp-ssl-ss
help_gridpane[gp-ssl-ss]="Generate self-signed certificate for GridPane site"
gp-ssl-ss () {
	DOMAIN="$1"

	if [[ -z $1 ]]; then
		echo "./gp-ssl-ss <domain>"
		if [[ -d /etc/nginx/ssl/${DOMAIN} ]]; then
			_error "There's already an SSL directory, quiting"
			exit 1
		else
			echo "No SSL directory...creating"
			mkdir /etc/nginx/ssl/${DOMAIN}
			cd /etc/nginx/ssl/${DOMAIN}
		fi
		echo "Generating self signed certificate"

	    openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -keyout cert.key -out cert.crt
	    openssl x509 -in cert.crt -out cert.pem
	    openssl rsa -in cert.key -out key.pem

		echo "Setting site to https + redis caching"
		gp conf -ngx -generate https-root redis ${1}
	fi
}

# -- gp-listsites
help_gridpane[gp-listsites]="List GridPane sites from /var/www, excluding canary and staging"
gp-listsites () {
	\ls -ld /var/www/*/ | grep -v -e 'canary' -e 'staging' -e 'gridpanevps' -e '22222' | awk '{print $9}' | sed 's|/var/www/||' | sed 's|/$||'
}

# -- gp-backupallsites
help_gridpane[gp-backupallsites]="Backup all sites on server to ~/backups"
gp-backupallsites () {
    SITES=$(gp-listsites)
    if [[ ! -d $HOME/backups ]]; then
        echo "$HOME/backups directory doesn't exist...creating..."
        mkdir $HOME/backups
    fi
    for SITE in ${(f)SITES}; do
        echo "Backing up ${SITE}..."
        /usr/local/bin/wp --allow-root --path=/var/www/${SITE}/htdocs db export - | gzip > ${HOME}/backups/db_${SITE}-$(date +%Y-%m-%d-%H%M%S).sql.gz
        tar --create --gzip --absolute-names --file=${HOME}/backups/wp_${SITE}-$(date +%Y-%m-%d-%H%M%S).tar.gz --exclude='*.tar.gz' --exclude='*.zip'--exclude='wp-content/cache' --exclude='wp-content/ai1wm-backups' /var/www/${SITE}/htdocs
    done
}
