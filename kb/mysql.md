# MySQL

# MySQL Tools
* Mytop - https://www.digitalocean.com/community/tutorials/how-to-use-mytop-to-monitor-mysql-performance

# MySQL .my.cnf Formatting
```
[client]
user=root
password="qweqwe"

[mysql]
user=root
password="qweqwe"

[mysqldump]
user=root
password="qweqwe"
```

# MySQL Commands
## Check System Variables
* SHOW VARIABLES LIKE '%max_connect_errors%';

# Tuning
## Guides
* https://www.percona.com/blog/2016/05/03/best-practices-for-configuring-optimal-mysql-memory-usage/

## Changes
* innodb_flush_method=O_DIRECT

# Settings
## innodb_flush_method
If you want to use OS caching for some storage engines. With InnoDB, we recommend innodb_flush_method=O_DIRECT  in most cases, which won’t use Operating System File Cache. However, there have been cases when using buffered IO with InnoDB made sense. If you’re still running MyISAM, you will need OS cache for the “data” part of your tables.
