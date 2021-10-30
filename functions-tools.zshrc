# -- Linux Specific
findswap () { find /proc -maxdepth 2 -path "/proc/[0-9]*/status" -readable -exec awk -v FS=":" '{process[$1]=$2;sub(/^[ \t]+/,"",process[$1]);} END {if(process["VmSwap"] && process["VmSwap"] != "0 kB") printf "%10s %-30s %20s\n",process["Pid"],process["Name"],process["VmSwap"]}' '{}' \; | awk '{print $(NF-1),$0}' | sort -h | cut -d " " -f2- }

# -- ssh/sshkeys
pk () { ls -1 ~/.ssh/*.pub | xargs -L 1 -I {} sh -c 'echo {};cat {};echo '-----------------------------''}

# -- nginx
nginx-inc () { cat $1; grep '^.*[^#]include' $1 | awk {'print $2'} | sed 's/;\+$//' | xargs cat }
nginx-log-404 () { awk '($8 ~ /404/)' $1 | awk '{print $8}' | sort | uniq -c | sort -rn }

# -- exim
eximcq () { exim -bp | exiqgrep -i | xargs exim -Mrm }

# -- curl
vh () { vh_run=$(curl --header "Host: $1" $2 --insecure -i | head -50);echo $vh_run }

# -- openssl
check_ssl () { echo | openssl s_client -showcerts -servername $1 -connect $1:443 2>/dev/null | openssl x509 -inform pem -noout -text }

# -- mysql functions
mysqldbsize () { mysql -e 'SELECT table_schema AS "Database", ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)" FROM information_schema.TABLES GROUP BY table_schema;' }
mysqltablesize () { mysql -e "SELECT table_name AS \"Table\", ROUND(((data_length + index_length) / 1024 / 1024), 2) AS \"Size (MB)\" FROM information_schema.TABLES WHERE table_schema = \"${1}\" ORDER BY (data_length + index_length) DESC;" }
mysqldbrowsize () { mysql -e "SELECT table_name, table_rows FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = \"${1}\" ;" }
msds () { zgrep "INSERT INTO \`$2\`" $1 |  sed "s/),/),\n/g" } # needs to be documented.
mysqlmyisam () { mysql -e "select table_schema,table_name,engine,table_collation from information_schema.tables where engine='MyISAM';" }
mysqlmax () { mysql -e "
	SELECT ( @@key_buffer_size
	+ @@innodb_buffer_pool_size
	+ @@innodb_log_buffer_size
	+ @@max_allowed_packet
	+ @@max_connections * ( 
	    @@read_buffer_size
	    + @@read_rnd_buffer_size
	    + @@sort_buffer_size
	    + @@join_buffer_size
	    + @@binlog_cache_size
	    + @@net_buffer_length
	    + @@net_buffer_length
	    + @@thread_stack
	    + @@tmp_table_size )
	) / (1024 * 1024 * 1024) AS MAX_MEMORY_GB;"
}


# -- WSL Specific Aliases
alias wsl-screen="sudo /etc/init.d/screen-cleanup start"

# -- Software
vhwinfo () { wget --no-check-certificate https://github.com/rafa3d/vHWINFO/raw/master/vhwinfo.sh -O - -o /dev/null|bash }
csf-install () { cd /usr/src; rm -fv csf.tgz; wget https://download.configserver.com/csf.tgz; tar -xzf csf.tgz; cd csf; sh install.sh }
github-cli () { sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0; sudo apt-add-repository https://cli.github.com/packages; sudo apt update; sudo apt install gh }

# -- Git
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