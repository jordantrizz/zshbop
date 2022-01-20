# ----------------------------
# -- Functions that are Tools!
# ----------------------------

# -- Linux Specific
findswap () { find /proc -maxdepth 2 -path "/proc/[0-9]*/status" -readable -exec awk -v FS=":" '{process[$1]=$2;sub(/^[ \t]+/,"",process[$1]);} END {if(process["VmSwap"] && process["VmSwap"] != "0 kB") printf "%10s %-30s %20s\n",process["Pid"],process["Name"],process["VmSwap"]}' '{}' \; | awk '{print $(NF-1),$0}' | sort -h | cut -d " " -f2- }

# -------------------
# -- SSH and SSH Keys
# -------------------
typeset -gA help_ssh

# List public ssh-keys
help_ssh[pk]='List public ssh-keys'
pk () { ls -1 ~/.ssh/*.pub | xargs -L 1 -I {} sh -c 'echo {};cat {};echo '-----------------------------''}

# Add SSH Key to keychain
help_ssh[addsshkey]='add ssh private key to keychain'
addsshkey () {
        echo "-- Adding $1 to keychain"
        keychain -q --eval --agents ssh $HOME/.ssh/$1
}

# -- Nginx
nginx-inc () { cat $1; grep '^.*[^#]include' $1 | awk {'print $2'} | sed 's/;\+$//' | xargs cat }
alias ngx404log="$ZSH_ROOT/bin/ngx404log.sh"

# -- Exim
eximcq () { exim -bp | exiqgrep -i | xargs exim -Mrm }

# -- curl
vh () { vh_run=$(curl --header "Host: $1" $2 --insecure -i | head -50);echo $vh_run }

# -- SSL
check_ssl () { echo | openssl s_client -showcerts -servername $1 -connect $1:443 2>/dev/null | openssl x509 -inform pem -noout -text }

# ------------------
# -- MySQL functions
#-------------------
# Init help array
typeset -gA help_mysql

# Add scripts
help_mysql_scripts[maxmysqlmem]='Calculate maximum MySQL memory'

# - mysqldbsize
help_mysql[mysqldbsize]='Get size of all databases in MySQL'
mysqldbsize () { 
	mysql -e 'SELECT table_schema AS "Database", ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)" FROM information_schema.TABLES GROUP BY table_schema ORDER BY (data_length + index_length) DESC;' 
}
# - mysqltablesize
help_mysql[mysqldtablesize]='Get size of all tables in MySQL'
mysqltablesize () { mysql -e "SELECT table_name AS \"Table\", ROUND(((data_length + index_length) / 1024 / 1024), 2) AS \"Size (MB)\" FROM information_schema.TABLES WHERE table_schema = \"${1}\" ORDER BY (data_length + index_length) DESC;" }

# - mysqldbrowsize
help_mysql[mysqldbrowsize]='Get number of rows in a table'
mysqldbrowsize () { mysql -e "SELECT table_name, table_rows FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = \"${1}\" ;" }

# - mysqldatafree
help_mysql[mysqldatafree]='List tables that have white space'
mysqldatafree () { mysql -e "SELECT ENGINE, TABLE_NAME,Round( DATA_LENGTH/1024/1024) as data_length , round(INDEX_LENGTH/1024/1024) as index_length, round(DATA_FREE/ 1024/1024) as data_free from information_schema.tables  where  DATA_FREE > 0;" }

# - msds
help_mysql[msds]='Undocumented'
msds () { zgrep "INSERT INTO \`$2\`" $1 |  sed "s/),/),\n/g" } # needs to be documented.

# - mysqlmyisam
help_mysql[msds]='Locate myisam tables in MySQL'
mysqlmyisam () { mysql -e "select table_schema,table_name,engine,table_collation from information_schema.tables where engine='MyISAM';" }

# - mysqlmax
help_mysql[msds]='Maximum potential memory usage by MySQL'
mysqlmax() { mysqltuner.pl | grep "Maximum possible memory usage" }
# Broken, needs fixing!
#mysqlmax () { mysql -e "
#	SELECT ( @@key_buffer_size
#	+ @@innodb_buffer_pool_size
#	+ @@innodb_log_buffer_size
#	+ @@max_allowed_packet
#	+ @@max_connections * ( 
#	    @@read_buffer_size
#	    + @@read_rnd_buffer_size
#	    + @@sort_buffer_size
#	    + @@join_buffer_size
#	    + @@binlog_cache_size
#	    + @@net_buffer_length
#	    + @@net_buffer_length
#	    + @@thread_stack
#	    + @@tmp_table_size )
#	) / (1024 * 1024 * 1024) AS MAX_MEMORY_GB;"
#}


# -- Software
vhwinfo () { wget --no-check-certificate https://github.com/rafa3d/vHWINFO/raw/master/vhwinfo.sh -O - -o /dev/null|bash }
csf-install () { cd /usr/src; rm -fv csf.tgz; wget https://download.configserver.com/csf.tgz; tar -xzf csf.tgz; cd csf; sh install.sh }
github-cli () { sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0; sudo apt-add-repository https://cli.github.com/packages; sudo apt update; sudo apt install gh }

# -- Git Repositories
repos () { 
	if [ ! $1 ]; then
		echo "repos <reponame>"
		echo "--"
		echo "gp-tools		-GridPane Tools"
	else
		if [ $1 = 'gp-tools' ]; then
			echo "-- Installing gp-tools repo"
			git clone https://github.com/jordantrizz/gp-tools.git $ZSH_ROOT/repos/gp-tools
		fi
	fi	
}


# -- Git Commands
gcp () {
	git commit -am "$*" &&	git push
}

# -- Setup Apps

ubuntu-netselect () {
	mkdir ~/tmp
        wget http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_amd64.deb -P ~/tmp
        sudo dpkg -i ~/tmpnetselect_0.3.ds1-28+b1_amd64.deb
}

setup-automysqlbackup () {
        cd $ZSH_ROOT/bin/AutoMySQLBackup
        ./install
}

# --------------------
# -- General functions
# --------------------

# -- Configure git
git_config () {
        vared -p "Name? " -c GIT_NAME
        vared -p "Email? " -c GIT_EMAIL
        git config --global user.email $GIT_EMAIL
        git config --global user.name $GIT_NAME
        git config --global --get user.email
        git config --global --get user.name
}