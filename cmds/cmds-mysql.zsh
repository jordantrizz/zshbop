# --
# MySQL commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[mysql]='MySQL related commands'

# - Init help array
typeset -gA help_mysql


# ===============================================
# -- mysql-db-size
# ===============================================
help_mysql[mysql-db-size]='Get size of all databases in MySQL'
function mysql-db-size () {
	_mysql-db-size-usage () {
		echo "Usage: mysql-db-size [-d <database> | -a | -l ]"
		echo ""
		echo "  -d <database>  - Get size of a specific database"
		echo "  -a             - Get size of all databases"
		echo "  -l             - List all databases"
	}
	local DATABASE=""
	zparseopts -D -E d:=ARG_DATABASE a=ARG_ALL l=ARG_LIST

	_debugf "ARG_DATABASE: $ARG_DATABASE ARG_ALL: $ARG_ALL ARG_LIST: $ARG_LIST"

	if [[ -n $ARG_DATABASE ]]; then
		DATABASE=${ARG_DATABASE[2]}
		_loading "Getting size of database $DATABASE"
		_mysql_wrapper -e "SELECT table_schema AS \"Database\", ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS \"Size (MB)\" FROM information_schema.TABLES WHERE table_schema = \"${DATABASE}\" GROUP BY table_schema;"
	elif [[ -n $ARG_ALL ]]; then
		_loading "Getting size of all databases"
		_mysql_wrapper -e "
		SELECT * FROM (
			SELECT 
				table_schema AS 'Database', 
				ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' 
			FROM 
				information_schema.TABLES 
			GROUP BY 
				table_schema
		) AS original_query
		UNION ALL
		SELECT 
			'Total' AS 'Database', 
			ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' 
		FROM 
			information_schema.TABLES
		ORDER BY 
			CASE 
				WHEN 'Database' = 'Total' THEN 1 
				ELSE 0 
			END, 
			'Size (MB)' DESC;
		"
	elif [[ -n $ARG_LIST ]]; then
		_loading "Listing all databases"
		mysql -e 'show databases'
	else
		_mysql-db-size-usage
		_error "Please specify an option to use, -d, -a or -l"
	fi
}

# ===============================================
# - mysql-db-rowsize-all
# ===============================================
help_mysql[mysql-db-rowsize-all]='The number of rows of all tables in MySQL'
mysql-db-rowsize-all () {
	if [[ $1 ]]; then
		LIMIT="limit $1"
	else
		LIMIT=""
	fi
	_mysql_wrapper -e "SELECT table_schema,table_name,table_rows FROM INFORMATION_SCHEMA.TABLES WHERE table_schema NOT IN ('performance_schema', 'sys') ORDER BY table_rows DESC ${LIMIT};"
}

# ===============================================
# - mysql-db-rowsize
# ===============================================
help_mysql[mysql-db-rowsize]='Get number of rows in a table'
mysql-db-rowsize () {
	if [[ -n $1 ]]; then
		_mysql_wrapper -e "SELECT table_schema,table_name,table_rows FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = \"${1}\" ORDER BY table_rows DESC;"
    else
        echo "Usage: $0 <database name>"
        return 1
    fi
}

# ===============================================
# - mysql-db-table-size
# ===============================================
help_mysql[mysql-db-table-size]='Get size of all tables in database'
mysql-db-table-size () {
	if [[ -n $1 ]]; then
		_mysql_wrapper -e "SELECT table_schema,table_name AS \"Table\", ROUND(((data_length + index_length) / 1024 / 1024), 2) AS \"Size (MB)\" FROM information_schema.TABLES WHERE table_schema = \"${1}\" ORDER BY (data_length + index_length) DESC;"
	else
		echo "Usage: $0 <database name>"
		return 1
	fi
}

# ===============================================
# - mysql-datafree
# ===============================================
help_mysql[mysql-datafree]='List tables that have white space'
mysql-datafree () {
	mysql -e "SELECT TABLE_SCHEMA, ENGINE, TABLE_NAME,Round( DATA_LENGTH/1024/1024) as data_length , round(INDEX_LENGTH/1024/1024) as index_length, round(DATA_FREE/ 1024/1024) as data_free from information_schema.tables where DATA_FREE > 0 ORDER by DATA_FREE DESC;"
}

# - mysql-msds
help_mysql[mysql-msds]='Undocumented, dont use.'
mysql-msds () {
	zgrep "INSERT INTO \`$2\`" $1 |  sed "s/),/),\n/g"
}

# ===============================================
# - mysql-myisam
# ===============================================
help_mysql[mysql-myisam]='Locate myisam tables in MySQL'
mysql-myisam () {
    _loading "Checking all databases for MyISAM Tables"
	mysql_output=$(_mysql_wrapper -e "select table_schema,table_name,engine,table_collation from information_schema.tables where engine='MyISAM';")
    if [[ $mysql_output ]]; then
        _loading2 "Found MyISAM tables"
        echo $mysql_output
    else
        _success "No MyISAM tables found"
        echo $mysql_output
    fi
}

# - mysql-maxmem
help_mysql[mysql-maxmem]="Maximum potential memory usage by via mysqltuner.pl"
mysql-maxmem() {
	mysqltuner.pl | grep -A3 "Maximum possible memory usage"
}

# -- mysql-currentmem
help_mysql[mysql-currentmem]="Current maximum memory usage"
mysql-currentmem () {
	MYSQL_CMD=""
	# -- check if we can connect to mysql
	MYSQL_TEST=$(mysql -e 'show processlist')
	if [[ $? -ge 1 ]]; then
		_cmd_exists mysql_config_editor
		if [[ $? -ge 1 ]]; then
			_error "Install mysql_config_editor"
			_error " -- Percona: apt-get install libperconaserverclient20-dev"
		else
			mysql_config_editor set --login-path=local --host=localhost --user=root --password
			MYSQL_CMD="--login-path=local"
		fi
	fi

	TMP_TABLE_SIZE=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from @@global.tmp_table_size)/1024/1024')
	KEY_BUFFER_SIZE=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from@@global.key_buffer_size)/1024/1024')
	INNODB_BUFFER_POOL_SIZE=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from @@global.innodb_buffer_pool_size)/1024/1024')
	INNODB_LOG_BUFFER_SIZE=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from @@global.innodb_log_buffer_size)/1024/1024')

	_notice "Not for running on older versions of MySQL"
	_notice " - innodb_additional_mem_pool_size depreciated in later versions"
	_loading "Calculating using the following"
	echo ""
	_loading2 "Instance Memory Total"
	echo "  tmp_table_size            = ${TMP_TABLE_SIZE} M"
	echo "  key_buffer_size           = ${KEY_BUFFER_SIZE} M"
	echo "  innodb_buffer_pool_size   = ${INNODB_BUFFER_POOL_SIZE} M"
	echo "  innodb_log_buffer_size    = ${INNODB_LOG_BUFFER_SIZE} M"
	echo ""
	echo "  query_cache_size - Usually not enabled so not checked."
	echo "  aria_pagecache_buffer_size - Usually not enabled so not checked"
	echo ""

	READ_BUFFER_SIZE=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from @@read_buffer_size)/1024')
	READ_RND_BUFFER_SIZE=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from @@read_rnd_buffer_size)/1024')
	SORT_BUFFER_SIZE=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from @@sort_buffer_size)/1024')
	THREAD_STACK=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from @@thread_stack)/1024')
	MYISAM_SORT_BUFFER_SIZE=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from @@myisam_sort_buffer_size)/1024')
	MAX_ALLOWED_PACKET=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from @@max_allowed_packet)/1024/1024')
	JOIN_BUFFER_SIZE=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select TRIM(LEADING '0' from @@join_buffer_size)/1024')
	MAX_CONNECTIONS=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select @@max_connections')
	MAX_USED_CONNECTIONS=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'show global status like "Max_used_connections"'| awk {'print $2'})


	_loading2 "Per thread * max_connections = ${MAX_CONNECTIONS} & max_used_connections = ${MAX_USED_CONNECTIONS}"
	echo "  read_buffer_size          = ${READ_BUFFER_SIZE} K"
	echo "  read_rnd_buffer_size      = ${READ_RND_BUFFER_SIZE} K"
	echo "  sort_buffer_size          = ${SORT_BUFFER_SIZE} K"
    echo "  thread_stack              = ${THREAD_STACK} K"
	echo "  myisam_sort_buffer_size   = ${MYISAM_SORT_BUFFER_SIZE} K"
	echo "  max_allowed_packet        = ${MAX_ALLOWED_PACKET} M"
	echo "  join_buffer_size          = ${JOIN_BUFFER_SIZE} K"
	echo ""

	mysql ${MYSQL_CMD} -e "select
        # -- GLOBAL_BUFFER_SIZE
        (@@GLOBAL.TMP_TABLE_SIZE + \
        @@GLOBAL.KEY_BUFFER_SIZE + \
        @@GLOBAL.INNODB_BUFFER_POOL_SIZE + \
        @@GLOBAL.INNODB_LOG_BUFFER_SIZE + \
        @@GLOBAL.NET_BUFFER_LENGTH)/1024/1024 as GLOBAL_BUFFER_SIZE, \
          # -- GLOBAL_THREAD_BUFFER_SIZE
        (@@GLOBAL.READ_BUFFER_SIZE + \
        @@GLOBAL.READ_RND_BUFFER_SIZE + \
        @@GLOBAL.SORT_BUFFER_SIZE + \
        @@GLOBAL.THREAD_STACK + \
        @@GLOBAL.MYISAM_SORT_BUFFER_SIZE + \
        @@GLOBAL.MAX_ALLOWED_PACKET + \
        @@GLOBAL.JOIN_BUFFER_SIZE)/1024/1024 as THREAD_BUFFER_SIZE_MB,
        # -- TOTAL_MEMORY_SIZE_KB
        #(@@GLOBAL.KEY_BUFFER_SIZE + \
        #@@GLOBAL.INNODB_BUFFER_POOL_SIZE + \
        #@@GLOBAL.INNODB_LOG_BUFFER_SIZE + \
        #@@GLOBAL.NET_BUFFER_LENGTH + \
        #(@@GLOBAL.SORT_BUFFER_SIZE + \
        #@@GLOBAL.MYISAM_SORT_BUFFER_SIZE + \
        #@@GLOBAL.READ_BUFFER_SIZE + \
        #@@GLOBAL.JOIN_BUFFER_SIZE + \
        #@@GLOBAL.READ_RND_BUFFER_SIZE) * \
        #@@GLOBAL.MAX_CONNECTIONS)/1024 AS TOTAL_MEMORY_SIZE_kb, \
        # -- TOTAL_MEMORY_SIZE_mb
        #    - Global
        (@@GLOBAL.TMP_TABLE_SIZE + \
        @@GLOBAL.KEY_BUFFER_SIZE + \
        @@GLOBAL.INNODB_BUFFER_POOL_SIZE + \
        @@GLOBAL.INNODB_LOG_BUFFER_SIZE + \
        @@GLOBAL.NET_BUFFER_LENGTH + \
        #     - Thread
        (@@GLOBAL.READ_BUFFER_SIZE + \
        @@GLOBAL.READ_RND_BUFFER_SIZE + \
        @@GLOBAL.SORT_BUFFER_SIZE + \
        @@GLOBAL.THREAD_STACK + \
        @@GLOBAL.MYISAM_SORT_BUFFER_SIZE + \
        @@GLOBAL.MAX_ALLOWED_PACKET + \
        @@GLOBAL.JOIN_BUFFER_SIZE) * \
         #    - Total + Max Connections
        @@GLOBAL.MAX_CONNECTIONS)/1024/1024 AS TOTAL_MEMORY_SIZE_mb, \
        # -- TOTAL_MEMORY_SIZE_gb
        #    - Global
        (@@GLOBAL.TMP_TABLE_SIZE +
        @@GLOBAL.KEY_BUFFER_SIZE + \
        @@GLOBAL.INNODB_BUFFER_POOL_SIZE + \
        @@GLOBAL.INNODB_LOG_BUFFER_SIZE + \
        @@GLOBAL.NET_BUFFER_LENGTH + \
        #    - Thread
        (@@GLOBAL.READ_BUFFER_SIZE + \
        @@GLOBAL.READ_RND_BUFFER_SIZE + \
        @@GLOBAL.SORT_BUFFER_SIZE + \
        @@GLOBAL.THREAD_STACK + \
        @@GLOBAL.MYISAM_SORT_BUFFER_SIZE + \
        @@GLOBAL.MAX_ALLOWED_PACKET + \
        @@GLOBAL.JOIN_BUFFER_SIZE) * \
        #    - Total + Max Connections
        @@GLOBAL.MAX_CONNECTIONS)/1024/1024/1024 AS TOTAL_MEMORY_SIZE_GB\G;"
        echo "Done."
        echo ""

    _loading2 "Total connection counts"
    mysql ${MYSQL_CMD} -e 'show global status like "%Max_used%"'

    INNODB_IO_CAPACITY=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select @@INNODB_IO_CAPACITY')
    INNODB_IO_CAPACITY_MAX=$(mysql ${MYSQL_CMD} --skip-column-names --silent --raw -e 'select @@INNODB_IO_CAPACITY_MAX')

    _loading2 "Innodb IO"
    echo " - https://dba.stackexchange.com/a/258935"
    echo " - https://dev.mysql.com/doc/refman/5.7/en/innodb-configuring-io-capacity.html"
    echo ""
    echo "  innodb_io_capacity        = ${INNODB_IO_CAPACITY}"
    echo "  innodb_io_capacity_max    = ${INNODB_IO_CAPACITY_MAX}"

}

# Broken, needs fixing! @@ISSUE
#mysqlmax () { mysql -e "
#       SELECT ( @@key_buffer_size
#       + @@innodb_buffer_pool_size
#       + @@innodb_log_buffer_size
#       + @@max_allowed_packet
#       + @@max_connections * (
#           @@read_buffer_size
#           + @@read_rnd_buffer_size
#           + @@sort_buffer_size
#           + @@join_buffer_size
#           + @@binlog_cache_size
#           + @@net_buffer_length
#           + @@net_buffer_length
#           + @@thread_stack
#           + @@tmp_table_size )
#       ) / (1024 * 1024 * 1024) AS MAX_MEMORY_GB;"
#}

# -- setup-automysqlbackup - Install automysqlbackup
help_mysql[mysql-setup-automysqlbackup]='Install automysqlbackup'
mysql-setup-automysqlbackup () {
        cd $ZSH_ROOT/bin/AutoMySQLBackup
        ./install
}

# -- mysql-listdbs - List databases.
help_mysql[mysql-listdbs]='List MySQL databases'
mysql-listdbs () {
	mysql -e 'show databases'
}

# -- mysql-logins - List MySQL logins.
help_mysql[mysql-logins]='List MySQL Logins'
mysql-logins () {
	mysql -e 'select host,user,password,plugin from mysql.user;'
}

# ===============================================
# -- mysql-backupall
# ===============================================
help_mysql[mysql-backup-all-dbs]='Backup all databases on server'
mysql-backup-all-dbs () {
    local MYSQL_BACKUP_HOST="127.0.0.1"
    local MYSQL_BACKUP_USER="root"
    
	_mysql-backup-all-dbs-usage () {
		echo "Usage: mysql-backupall [-d <backup-dir>] [-h <host>] [-u <username>] [-p]"
        echo ""
		echo "Options"
		echo "  -d        - Directory to store backups, otherwise \$HOME/db-backups"
		echo "  -h        - MySQL Host, defaults to localhost"
		echo "  -u        - MySQL Username, defaults to root"
		echo "  -p        - Ask for MySQL password"
		echo ""
        echo "  Example: mysql-backupdbs 127.0.0.1 root yes"
        echo "   By default use ~/.my.cnf or specify host and username which is optional"
        echo "   Default host = 127.0.0.1, default username = root"
        echo ""
	}

	# Parse options
	zparseopts -D -E d:=ARG_BACKUP_DIR h:=ARG_HOST u:=ARG_USER p=ARG_PASSWORD
	[[ $ARG_BACKUP_DIR ]] && BACKUP_DIR=${ARG_BACKUP_DIR[2]} || BACKUP_DIR="$HOME/db-backups"
	[[ $ARG_HOST ]] && MYSQL_BACKUP_HOST=${ARG_HOST[2]}
	[[ $ARG_USER ]] && MYSQL_BACKUP_USER=${ARG_USER[2]}
	[[ $ARG_PASSWORD ]] && ASK_PASSWORD=1 || ASK_PASSWORD=0

	# Date mm-dd-YYYY-HH_MM_SS
	local MYSQL_BACKUPALL_DATE=`date +%m-%d-%Y-%H_%M_%S`	

	# Check if backup dir exists
	if [[ ! -d $BACKUP_DIR ]]; then
		mkdir -p $BACKUP_DIR
	fi

	# Confirm actions
	_loading "Backing up all databases on ${MYSQL_BACKUP_HOST} as ${MYSQL_BACKUP_USER} to ${BACKUP_DIR}"
	echo "Proceed? [y/n]"
	read REPLY
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "Aborting..."
		return 1
	fi

	# -- Start backup of all DB's
    _loading "Running backup of all DB's"
	_loading2 "mysql -h ${MYSQL_BACKUP_HOST} -u ${MYSQL_BACKUP_USER} -N -e 'show databases'"
    DB_NAMES=($(mysql -h ${MYSQL_BACKUP_HOST} -u ${MYSQL_BACKUP_USER} -N -e 'show databases;'))
	if [[ $? == "1" ]]; then
		_error " -- Error getting database list"
		return 1
	else
    	_loading2 "Found Databases - ${DB_NAMES[@]}"
	fi

    for dbname in "${DB_NAMES[@]}"; do
		# Skip these databases
		if [[ $dbname == "performance_schema" ]] || [[ $dbname == "information_schema" ]] || [[ $dbname == "mysql" ]] || [[ $dbname == "sys" ]]; then
			_loading3 " -- Skipping $dbname"
			continue
		fi
		_loading3 "Backing up $dbname to $BACKUP_DIR/${dbname}-${MYSQL_BACKUPALL_DATE}.sql"
        mysqldump -h $MYSQL_BACKUP_HOST -u $MYSQL_BACKUP_USER --complete-insert --routines --triggers --single-transaction "$dbname" > "$BACKUP_DIR/${dbname}-${MYSQL_BACKUPALL_DATE}.sql"
		if [[ $? == "1" ]]; then
			_error " -- Error backing up $dbname"
		else
			_success " -- Completed backup of $dbname to $BACKUP_DIR/${dbname}-${MYSQL_BACKUPALL_DATE}.sql"
		fi
    done
}

# ===============================================
# -- mysql-backup-db
# ===============================================
help_mysql[mysql-backup-db]='Backup a single databases on a server'
mysql-backup-db () {
	local BACKUP_DIR="$HOME/backups"
    if [[ -z $1 ]];then
	    echo "Usage: mysql-backupdb [-d <database>|-l]"
    	return
	fi

	zparseopts -D -E d:=ARG_DATABASE l=ARG_LIST

	if [[ -n $ARG_DATABASE ]]; then
		DATABASE=${ARG_DATABASE[2]}
		# Check if backup dir exists
		if [[ ! -d $BACKUP_DIR ]]; then
			mkdir -p $BACKUP_DIR
		fi
		
		_loading "Running backup of database: $DATABASE"
		local MYSQL_BACKUPDB_DATE=`date +%m-%d-%Y-%H_%M_%S`
		local MYSQL_BACKUP_FILE="$BACKUP_DIR/${DATABASE}-${MYSQL_BACKUPDB_DATE}.sql"
		
		_loading2 "-- Running backup of $DATABASE to $MYSQL_BACKUP_FILE"
		_loading3 "_mysqldump_wrapper $DATABASE > $MYSQL_BACKUP_FILE"

		_mysqldump_wrapper $DATABASE > $MYSQL_BACKUP_FILE
		if [[ $? == "1" ]]; then
			_error " -- Error backing up $DATABASE"
		else
			_success " -- Completed backup of $DATABASE to $MYSQL_BACKUP_FILE"
		fi	
	elif [[ -n $ARG_LIST ]]; then
		_loading "Listing all databases"
		_mysql_wrapper -e 'show databases'
	else
		_mysql-backup-db-usage
		_error "Please specify an option to use, -d or -l"
	fi
}

# ===============================================
# -- mysql-mycli
# ===============================================
help_mysql[mysql-mycli]="Install and run mycli"

# ===============================================
# -- mysqlt
# ===============================================
help_mysql[mysqlt]="Run mysqltuner.pl --noinfo --nogood"
mysqlt () {
	mysqltuner.pl --noinfo --nogood
}

# ===============================================
# -- mysqlt-html
# ===============================================
help_mysql[mysqlt-html]="Run mysqltuner.pl --verbose --json | j2 -f json basic.html.j2 > mysql.html"
mysqlt-html () {
	# might need apt-get install libjson-perl
	mysqltuner.pl --verbose --json | j2 -f json $ZBR/bin/MySQLTuner-perl/templates/basic.html.j2 > mysql.html
}

# ===============================================
# -- mysql-create-user
# ===============================================
help_mysql[mysql-create-user]="Create MySQL 8.0 user, provide username as first argument and a random password will be generated"
mysql-create-user () {
	MYSQL_USER="$1"
	if [[ -z $MYSQL_USER ]]; then
		echo "Usage: mysql-createuser <user>"
		return 1
	else
		RND_PASS=$(genpass-monkey)
		_loading "Creating user $1 with password ${RND_PASS}"
		OUTPUT=$(mysql -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${RND_PASS}';")
		echo $OUTPUT
	fi
}

# -- mysql-ps
help_mysql[mysql-ps]="Show current mysql processes"
mysql-ps () {
	mysql -e 'show full processlist'
}

# ===============================================
# -- mysql-myisam2innodb
# ===============================================
help_mysql[mysql-myisam2innodb]="Convert MyISAM to Innodb"
function mysql-myisam2innodb () {
	_mysql-myisam2innodb-usage () {
		echo "Usage: mysql-myisam2innodb [-d<database>|-a] -b"
		echo "Commands:"
		echo "  -d <database>  - Convert MyISAM tables to InnoDB in a specific database"
		echo "  -a             - Convert MyISAM tables to InnoDB in all databases"
		echo "Options:"
		echo "  -sb             - Skip backup"
	}

	_mysql-myisam2innodb-get-tables () {
		local DATABASES
		# Find all databases that have myisam tables
		DATABASES=$(_mysql_wrapper -e "SHOW DATABASES;" | awk '{print $1}')
		echo "$DATABASES" | while read database; do
			if [[ $database != "Database" ]]; then
				TABLES=$(_mysql_wrapper $database -e "SHOW TABLE STATUS
				WHERE Engine = 'MyISAM';" | awk '{print $1}')
				if [[ -n $TABLES ]]; then
					echo "$database"				
				fi
			fi
		done		
	}

	_mysql-myisam2innodb-convert () {
		DATABASE=$1
		# Backup Database?
		if [[ $SKIP_BACKUP == 0 ]]; then
			_loading2 "Backup database (${DATABASE}) before converting? [y/n]"
			read REPLY
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				mysql-backup-db -d $DATABASE
			fi
		else
			_loading2 "Skipping backup of database ${DATABASE}"
		fi

		echo "Upgrading MyISAM tables to InnoDB in database $DATABASE..."
		TABLES=$(_mysql_wrapper $DATABASE -e "SHOW TABLE STATUS WHERE Engine = 'MyISAM';" | awk '{print $1}')

		echo "$TABLES" | while read table; do
			if [[ $table != "Name" ]]; then
				echo "Upgrading table $table to InnoDB..."
				_mysql_wrapper $DATABASE -e "ALTER TABLE $table ENGINE=InnoDB;"
				echo "Table $table upgraded to InnoDB successfully."
			fi
		done
		echo "All MyISAM tables have been upgraded to InnoDB."
	}

	local DATABASE MODE
	local MYISAM_DATABASES=()
	local SKIP_BACKUP=0

	zparseopts -D -E d:=ARG_DATABASE a=ARG_ALL sb=ARG_SKIP_BACKUP	
	[[ $ARG_DATABASE  ]] && DATABASE=${ARG_DATABASE[2]}
	[[ $ARG_ALL ]] && MODE="all" || MODE="single"
	[[ $ARG_SKIP_BACKUP ]] && SKIP_BACKUP=1
	
	[[ -z $MODE ]] && { _mysql-myisam2innodb-usage; _error "Please specify an option to use, -d or -a"; return 1; }

	[[ $MODE == "single" ]] && [[ -z $DATABASE ]] && { _mysql-myisam2innodb-usage; _error "Please specify a database to convert"; return 1; }

	if [[ $MODE == "single" ]]; then
		_loading "Upgrading MyISAM tables to InnoDB in database $DATABASE..."
		_mysql-myisam2innodb-convert $DATABASE
	elif [[ $MODE == "all" ]]; then
		_loading "Upgrading all MyISAM tables to InnoDB..."
		MYISAM_DATABASES=($(_mysql-myisam2innodb-get-tables))
		
		if [[ -z $MYISAM_DATABASES ]]; then
			_success "No MyISAM tables found"
			return 1
		else
			_success "Found MyISAM tables in the following databases: ${MYISAM_DATABASES[@]}"
		fi

		for DATABASE in "${MYISAM_DATABASES[@]}"; do
			_loading3 "Processing database $DATABASE..."
			_mysql-myisam2innodb-convert $DATABASE
		done
		_success "All MyISAM tables in all databases have been upgraded to InnoDB."
		echo "All MyISAM tables in all databases have been upgraded to InnoDB."
	else
		_mysql-myisam2innodb-usage
		_error "Please specify an option to use, -d or -a"
		return 1
	fi
}

# -- mysql-uptime
help_mysql[mysql-uptime]="Get MySQL uptime."
mysql-uptime () {
    mysql -e "select TIME_FORMAT(SEC_TO_TIME(VARIABLE_VALUE ),'%Hh %im') as Uptime from performance_schema.global_status where VARIABLE_NAME='Uptime';"
}

# ===============================================
# -- mysql-config
# ===============================================
help_mysql[mysql-config]='Output MySQL running configuration'
mysql-config () {
	$MYSQL_BIN --raw -B -N -e 'SHOW VARIABLES;'
}

# -- mysql-adddb
help_mysql[mysql-adddb]='Add a database'
function mysql-adddb () {

		# -- Check if user is root
		if [[ _checkroot == 1 ]]; then
		echo "This script must be run as root"
		return 1
		fi

		# -- Set variables
		MYSQL_USER="$1"
		MYSQL_DB="$2"
		MYSQL_PASS="$3"

		# Check for arguments
		if [[ -z $MYSQL_USER ]] && [[ -z $MYSQL_PASS ]]; then
			echo "Usage: mysql-adddb <user> <database name> <optional-password>"
			return 1
		fi

		# -- Check if $MYSQL_USER is less than 16 characters.
		if [[ ${#MYSQL_USER} -gt 16 ]]; then
			echo "Username has to be 16 or less. Please shorten the username"
			return 1
		fi

		# -- Check databsae name for "-".
		if [[ $MYSQL_DB == *-* ]]; then
			echo "Database Name has a \"-\" in it, not allowed."
			return 1
		fi

		# -- Check if database exists
		if [[ $(mysql -e "SHOW DATABASES LIKE '${MYSQL_DB}';" -s --skip-column-names) == $MYSQL_DB ]]; then
			echo "Database ${MYSQL_DB} already exists"
			return 1
		fi

		# -- Check if user exists
		if [[ $(mysql -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '${MYSQL_USER}');" -s --skip-column-names) == 1 ]]; then
			echo "User ${MYSQL_USER} already exists"
			return 1
		fi

		# -- Check if password is provided
		if [[ -z $MYSQL_PASS ]]; then
			_loading3 "No password provided, generating random password"
			MYSQL_PASS=$(genpass-monkey)
		else
			_loading3 "Using provided password"
		fi

		# -- Print out what is going to happen
		echo "Creating database ${MYSQL_DB} for user ${MYSQL_USER} with password ${MYSQL_PASS}"
		echo "Proceed? [y/n]"
		read REPLY

		if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Proceeding..."

		# -- Create database
		mysql -e "CREATE DATABASE ${MYSQL_DB};"
		if [[ $? == 1 ]]; then
			echo "Error creating database ${MYSQL_DB}"
			return 1
		else
			echo "Database ${MYSQL_DB} created successfully"
		fi

		# -- Create user
		mysql -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';"
		if [[ $? == 1 ]]; then
			echo "Error creating user ${MYSQL_USER}"
			return 1
		else
			echo "User ${MYSQL_USER} created successfully"
		fi

		# -- Grant Permissions
		mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'localhost';"
		if [[ $? == 1 ]]; then
			echo "Error granting permissions to ${MYSQL_USER}"
			return 1
		else
			echo "Permissions granted successfully"
		fi

		# -- Flush privileges
		mysql -e "FLUSH PRIVILEGES;"
		if [[ $? == 1 ]]; then
			echo "Error flushing privileges"
			return 1
		else
			echo "Privileges flushed successfully"
		fi

		# -- Return password
		echo "Successfully created database ${MYSQL_DB} for user ${MYSQL_USER} with password ${MYSQL_PASS}"

		# -- Return 0
		return 0
	else
		echo "Aborting..."
		return 1
	fi
}

# ==============================================================================
# -- mysql-backup-mydumper
# ==============================================================================
help_mysql[mysql-backup-mydumper]='Backup MySQL databases using mydumper'
function mysql-backup-mydumper () {
	measure_time() {
		start_time=$(date +%s)
		"$@"
		end_time=$(date +%s)
		echo $((end_time - start_time))
	}

	if [[ -z $1 ]]; then
		echo "Usage: mysql-backup-mydumper <database>"
		return 1
	fi

	local DATABASE="$1"	
	local BACKUP_DATE=$(date +%Y-%m-%d-%H-%M-%S)
	local BACKUP_DIR="$HOME/backups/${DATABASE}-${BACKUP_DATE}-dumper/"

	# -- Check if mydumper is installed
	_cmd_exists mydumper
	if [[ $? == 1 ]]; then
		_error "mydumper is not installed"
		return 1
	fi

	# -- Check if database exists
	if [[ $(mysql -e "SHOW DATABASES LIKE '${DATABASE}';" -s --skip-column-names) != $DATABASE ]]; then
		echo "Database ${DATABASE} does not exist"
		return 1
	fi

	# -- Check if backup directory exists
	if [[ ! -d $BACKUP_DIR ]]; then
		mkdir -p $BACKUP_DIR
	fi

	# -- Run backup and time
	_loading "Running backup of ${DATABASE}"
	
	# Time backup in seconds and store in $BACKUP_TIME
	BACKUP_TIME=$(measure_time mydumper -B ${DATABASE} -o ${BACKUP_DIR})

	# -- Check if backup was successful
	if [[ $? == 0 ]]; then
		_success "Backup of ${DATABASE} completed successfully"
		_success "Backup file: ${BACKUP_DIR}"
		_success "Backup time: ${BACKUP_TIME}"
	else
		_error "Backup of ${DATABASE} failed"
	fi
}

