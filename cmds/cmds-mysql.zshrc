# --
# MySQL commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_mysql

# - mysql-dbsize
help_mysql[mysql-dbsize]='Get size of all databases in MySQL'
mysql-dbsize () {
        mysql -e 'SELECT table_schema AS "Database", ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)" FROM information_schema.TABLES GROUP BY table_schema ORDER BY (data_length + index_length) DESC;'
}
# - mysql-dbrowsize
help_mysql[mysql-dbrowsize]='Get number of rows in a table'
mysql-dbrowsize () { mysql -e "SELECT table_name, table_rows FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = \"${1}\" ;" }

# - mysqltablesize
help_mysql[mysqldtablesize]='Get size of all tables in MySQL'
mysqltablesize () { 
	mysql -e "SELECT table_name AS \"Table\", ROUND(((data_length + index_length) / 1024 / 1024), 2) AS \"Size (MB)\" FROM information_schema.TABLES WHERE table_schema = \"${1}\" ORDER BY (data_length + index_length) DESC;" 
}

# - mysql-datafree
help_mysql[mysql-datafree]='List tables that have white space'
mysql-datafree () { 
	mysql -e "SELECT ENGINE, TABLE_NAME,Round( DATA_LENGTH/1024/1024) as data_length , round(INDEX_LENGTH/1024/1024) as index_length, round(DATA_FREE/ 1024/1024) as data_free from information_schema.tables where DATA_FREE > 0;" 
}

# - mysql-msds
help_mysql[mysql-msds]='Undocumented, dont use.'
mysql-msds () { 
	zgrep "INSERT INTO \`$2\`" $1 |  sed "s/),/),\n/g" 
}

# - mysql-myisam
help_mysql[msds]='Locate myisam tables in MySQL'
mysqlmyisam () { 
	mysql -e "select table_schema,table_name,engine,table_collation from information_schema.tables where engine='MyISAM';" 
}

# - mysql-maxmem
help_mysql[mysql-maxmem]='Maximum potential memory usage by MySQL'
mysql-maxmem() { 
	mysqltuner.pl | grep "Maximum possible memory usage" 
}

# Broken, needs fixing!
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