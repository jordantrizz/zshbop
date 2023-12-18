# Enhance
## Common File Locations
* Site Logs: /var/local/enhance/webserver_logs/
* Litespeed Error Log: /var/local/enhance/litespeedlogs/error.log
* Litespeed Configuration: /var/local/enhance/litespeed

# Common CLI Commands
## Control Panel
* appcd-cli change-webserver lite-speed - Change webserver to LiteSpeed, rebuilds docker container.
* 
# MySQL
* Configuration: /var/local/enhance/mysql/conf.d/enhance.cnf

# Docker
## Common Commands
* Start Docker Container and show output - docker start 01a31fd0ca8e -ai
* Stop Docker Container - docker stop 01a31fd0ca8e

# Common Issues
## New Server Not Showing in Control Panel
* Check `journalctl -u enhcontrold` for errors
* Try running /var/local/enhance/controld/enhcontrold
## wp-cli as root
* apt-get install -y --no-install-recommends php-cli php-mysql
* Edit /etc/php/8.1/cli/php.ini
```
mysqli.default_socket = /var/local/enhance/mysqlcd-run/mysqld.sock
```
You might also need to run the following
```
mkdir -p /var/run/mysqld
ln -s /var/local/enhance/mysqlcd-run/mysqld.sock /var/run/mysqld/mysqld.sock
```
## Rotate site error logs
Note: Currently broken due to permissions.
Add to /etc/logrotate.d/error_logs
```
/var/www/*/error_log {
    daily
    rotate 15
    size 500M
    compress
    missingok
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        for log in /var/www/*/error_log; do
            owner=$(stat -c "%U:%G" "$(dirname "$log")")
            chown $owner "$log"
        done
    endscript
}
```
## Rotate mysql logs if enabled
1. Setup logs for mysql
edit /var/local/enhance/mysql/conf.d/enhance.cnf and add
```
log-error = /var/lib/mysql/mysql.log
slow_query_log = 1
slow_query_log_file = /var/lib/mysql/mysql-slow.log
long_query_time = 5
#log_queries_not_using_indexes = 1
```
1. Add to /etc/logrotate.d/mysql_logs
```
/var/local/enhance/mysqlcd-data/data/mysql.log /var/local/enhance/mysqlcd-data/data/mysql-slow.log{
    daily
    size 500M
    rotate 15
    compress
    delaycompress
    missingok
    create 0640 lxd docker
    sharedscripts
    postrotate
        /usr/bin/mysqladmin flush-logs
     
```
# Notes
## Litespeed lsphp Containers
```
Message: Hi Jordan,

lsphp runs from within the website's PHP container which is a combination of overlayfs mounts, starting from /var/enhance_container_images/jammy (PHP >= 8.1) or /var/enhance_container_images/focal (PHP < 8.1) then your chosen PHP version (ie. /var/enhance_container_images/php82) then files specific to that website's container.

There is no official way to load extra modules into PHP. Most of the modules you could possibly way are already included but xdebug isn't currently one of them. We can consider a feature request to add this to the next PHP package update, in approximately 1-2 weeks.

If you want to add it right now, you can build it manually (on another system) for your chosen PHP then upload it to the website's home dir and add to php.ini (under "developer tools")

extension=xdebug.so

It's very similar to Docker, it's just cgroups and namespaces implemented with native syscalls + overlayfs. The reason it's done outside of Docker is for speed - some customers run thousands of websites per server and the startup performance of Docker is insufficient.

Yes you could compile the extension on the host o/s, that should work fine.
``