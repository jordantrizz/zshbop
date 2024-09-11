# MySQL



## MySQL .my.cnf Formatting
```
[client] # important for mysqltuner.pl
user=root
password="qweqwe"

[mysql]
user=root
password="qweqwe"

[mysqldump]
user=root
password="qweqwe"
```

# Common MySQL Commands
## Check System Variables
* SHOW VARIABLES LIKE '%max_connect_errors%';

## Databases
* ```create database <database>```
* ```drop database <database>```

## Tables SELECT, INSERT, DELETE and UPDATE
### SELECT
### INSERT
* ```INSERT INTO table_name (column1, column2, column3, ...) VALUES (value1, value2, value3, ...);```
* ```INSERT INTO table_name VALUES (value1, value2, value3, ...);```
* ```INSERT INTO Customers (CustomerName, ContactName, Address, City, PostalCode, Country) VALUES ('Cardinal', 'Tom B. Erichsen', 'Skagen 21', 'Stavanger', '4006', 'Norway');```

### DELETE
*

### UPDATE
*

# Tuning
## Guides
* https://www.percona.com/blog/2016/05/03/best-practices-for-configuring-optimal-mysql-memory-usage/

## Changes
* innodb_flush_method=O_DIRECT

# Settings
## innodb_flush_method
* If you want to use OS caching for some storage engines. 
* With InnoDB, we recommend innodb_flush_method=O_DIRECT
* In most cases, which won’t use Operating System File Cache. 
* However, there have been cases when using buffered IO with InnoDB made sense. 
* If you’re still running MyISAM, you will need OS cache for the “data” part of your tables.


## MySQL Tools
### MyTop
* Mytop - https://www.digitalocean.com/community/tutorials/how-to-use-mytop-to-monitor-mysql-performance

### MySQL Tuner
https://github.com/major/MySQLTuner-perl

### automysqlbackup
https://sourceforge.net/projects/automysqlbackup/

#### Backup user.
Sometimes you have to do both localhost and 127.0.0.1 depending.
```
CREATE USER 'automysqlbackup'@'localhost' IDENTIFIED BY 'secure-password';
CREATE USER 'automysqlbackup'@'127.0.0.1' IDENTIFIED BY 'secure-password';
GRANT SELECT, SHOW VIEW, LOCK TABLES, EVENT ON *.* TO 'automysqlbackup'@'localhost';
GRANT SELECT, SHOW VIEW, LOCK TABLES, EVENT ON *.* TO 'automysqlbackup'@'127.0.0.1'
GRANT EXECUTE ON sys.* TO 'automysqlbackup'@'localhost';
GRANT EXECUTE ON sys.* TO 'automysqlbackup'@'127.0.0.1';
FLUSH PRIVILEGES;
FLUSH PRIVILEGES;
EXIT;
```

#### Configuration
```
CONFIG_backup_dir='/var/backup/db'
CONFIG_db_exclude=( 'performance_schema' 'information_schema' )
CONFIG_db_exclude_pattern=()
CONFIG_do_monthly="01"
CONFIG_do_weekly="5"
CONFIG_rotation_daily=7
CONFIG_mysql_dump_latest='yes'
CONFIG_mysql_dump_max_allowed_packet='512M'
CONFIG_mysql_dump_username='automysqlbackup'
CONFIG_mysql_dump_password='secure-password'
CONFIG_mysql_dump_host='localhost'
CONFIG_mysql_dump_port=3306
CONFIG_mysql_dump_socket=''
```

#### Cron
```
# Runs at 00:00 every day
0 0 * * * /usr/local/bin/automysqlbackup
```

# Notes
## Enable Password Authentication
```
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'test';
```

## Print Out Raw Data
* mysql -B or mysql --batch
* mysql -r

## Remove headers
```
mysql -s
```

# Common issues
## Unknown table 'COLUMN_STATISTICS' in information_schema (1109)
For reference, mysqldump 8 is now expecting a information_schema.COLUMN_STATISTICS table.

On MariaDB there is no such column in information_schema: https://jira.mariadb.org/browse/MDEV-16555

This one seems pretty big and very surprising to me, mysqldump8 just broke the MariadDB compatibility and there's not even a fix in the new Ubuntu LTS.

Workaround: snipe/snipe-it#6800 (comment)

* https://stackoverflow.com/questions/11657829/unknown-table-column-statistics-in-information-schema-1109
