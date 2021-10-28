<!--ts-->
   * [Ultimate Tool Box for Systems Administration](#ultimate-tool-box-for-systems-administration)
   * [Tools](#tools)
      * [PHP](#php)
         * [memory.php](#memoryphp)
      * [Linux Scripts](#linux-scripts)
         * [webprotect](#webprotect)

<!-- Added by: jtrask, at: Thu  2 May 2019 12:31:49 PDT -->

<!--te-->
# Ultimate Tool Box for Systems Administration
This repository was created as a means to track the collection of scripts used for system administration on linux systems.
# Tools
## File Transfer
Command | Description | Example
 --- | --- | --- |
parsyncfp | Parellel rsync | parsyncfp --maxload=5.5 --NP=10 --startdir='/home/user' public_html root@server.com:/home/user
## Database
Script | Description
 --- | --- |
mybkdb | Backup a MySQL database.

## PHP
Script | Description|
 --- | --- |
memory.php | Test PHP memory exhaustion, details in code.
php-cpu-test.php | Run's a simple round of PHP functions to test the CPU response time.
mysql_test.php | Test if a MySQL database works via PHP mysqli

## Linux Scripts
Command | Description|
 --- | --- |
webprotect | Generate apache password protection.
adddb | Add a MySQL database
addwww | Add a local user and configuration to NGiNX based on templates.
rndpass.pl | A random password generator written in perl.
mysqltuner.pl | The usual http://mysqltuner.pl
mybkdb-all | Backup all MySQL Databases on a host into the current working directory under the backup folder

# Contributing
## Adding GIT Repositories
* ```git submodule add https://github.com/reorx/httpstat.git```
* Add new tool to $PATH
## Removing GIT Repositories# Adding GIT Repositories
* ```git submodule add https://github.com/reorx/httpstat.git```
* Add new tool to $PATH
