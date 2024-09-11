AutoMariaDBBackup
===============
 A fork and further development of AutoMySQLBackup from sourceforge. http://sourceforge.net/projects/automysqlbackup/

Information
-----------

Creating backups means copy the data in a way where it can be restored again. To backup a mariadb database server in most cases it is needed to create a dump from the database and each table. If the data, mariadb stores in its data directory is simply copied, restoring the data in the mariadb database will not be possible. This command line tool enables you to create and maintian mariadb backups. You can backups of innodb and myisam tables.

Automariadbdumper uses mariadbdump for creating the sql backup. By default databases are backed up in separate gzipped files. To restore a database you can use:

```
zcat daily_andi_wiki_2016-12-24_03h59m_Saturday.sql.gz | mariadb -u root -p
```

Change the name of the file to your needs. After this simple step you get back the data into your database.

To setup this script have a look at the automariadbbackup.conf file. In there you have several options to configure the mariadb backup script to your needs.

Adjustments
-----------

You can find some original files from the sourceforge package. Some files are adjusted to my needs:
- support for MariaDB 10.4.6 and above


MariaDB
-------
To use backup MariaDB databases, specify `CONFIG_mariadb_dump_username` and `CONFIG_mariadb_dump_password` like you would with the SourceForge version.

Get Involved
------------
Backup your mariadb server with ease by using this adjusted script. If you encounter any errors feel free to [drop an issue](https://github.com/official_tisao/AutoMariaDBBackup/issues/new). 
