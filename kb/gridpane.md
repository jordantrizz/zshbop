# Popular Links
* [Gridpane Cheatsheet CLI](https://managingwp.io/2021/05/13/gridpane-cli-cheatsheet/)

# GridPane CLI Commands

## Set Default Site
* gp site {site.url} -set-nginx-default
## Default Site Redirect
<meta http-equiv="refresh" content="0; URL='https://site.com/?utm_source=gridpane&utm_medium=redirect&utm_campaign=default'" />

## Suspend a Site
* gp site {site.url} -suspend
* Utilizes /var/www/holding.html so update this file if needed.

## Clear site cache
* gp fix cached eiexperience.com - Clear single site cache
* gp fix clear-cache - Clear all site cache.

# Advanced
## Setup System Cron for WordPress
* gp site {site.url} -gpcron-on {minute.interval}

## Check and Download Latest GridPane Scripts
* /usr/local/bin/gpupdate

# SSL
## PHPMyAdmin SSL
* gp site phpma -ssl-renewal

## Monit
### Run Monit Check for SSL Renewals
* gp site monit -ssl-renewal
### Run Monit Check for MySQL
* gpmonit mysql
### Change GridPane Monit Alert and Restart
* gpmonit mysql -mem-high-mb 900 -mem-restart-mb 1024 

# MySQL
## MySQL Service Control
* gp mysql -stop
* gp mysql -start
* gp mysql -restart
* gp mysql -reload

## MySQL Logins
* gridenv/promethean.env - root login stored
* gp mysql -get-pass root - get root login
* gp mysql -login root - login as root login
* gp mysql -get-pass {site.url} - get site db login
* gp mysql -login {site.url} - login as site db user

## MySQL Configuration
The default values are specified

* gp stack mysql -binlog-expire-logs-seconds 2592000
* gp stack mysql -innodb-autoinc-lock-mode 1
* gp stack mysql -innodb-buffer-pool-instances 8 (or 1 if innodb_buffer_pool_size < 1GB)
* gp stack mysql -innodb-buffer-pool-size 64 MB if the total RAM is less than 1200MB at the time the server is provisioned, or 128MB if more.
* gp stack mysql -innodb-flush-log-at-trx-commit 1
* gp stack mysql -innodb-flush-method O_DIRECT
* gp stack mysql -innodb-io-capacity 1000
* gp stack mysql -innodb-io-capacity-max 2000
* gp stack mysql -innodb-log-file-size 100
* gp stack mysql -join-buffer-size 256
* gp stack mysql -long-query-time 0 
* gp stack mysql -max-binlog-size 100
* gp stack mysql -max-connections 150
* gp stack mysql -slow-query-log 0
* gp stack mysql -thread-handling one-thread-per-connection
* gp stack mysql -thread-pool-high-prio-mode transactions
* gp stack mysql -thread-pool-high-prio-tickets 4294967295
* gp stack mysql -thread-pool-idle-timeout 60
* gp stack mysql -thread-pool-max-threads 100000
* gp stack mysql -thread-pool-size 4 - Based on CPU cores - This variable is inactive unless thread_handling is set to pool-of-threads
* gp stack mysql -thread-pool-stall-limit 500

MySQL slow query log output can be viewed in the following log: /var/log/mysql/slow.log
* gp mysql restart

# Redis
## Redis Cache Expiry
* gp stack nginx redis -site-cache-valid {accepted.value} {site.url}

## Clear Site Redis Full Page Cache
* gp fix cache cached site.com

# PHP
## Change PHP Settings
* https://gridpane.zendesk.com/hc/en-us/articles/360038296712-Configure-PHP
## Update PHP memory per PHP version.
* gp stack php 7.4 -mem-limit 512 -no-reload &&
## Update PHP memory per site.
* gp stack php -site-mem-limit 512 test.com

# Cache
## Commands
* wp nginx-helper purge-all

# Backups
## Local Backup Commands
* ```/usr/local/bin/gpbup domain.com -get-available-backups```

## List local backup snapshots for sites.
* find /opt/gridpane/backups/duplications/snapshots -type f | awk -F’/’ ‘{print $7}’ | sort | uniq | sed “s/gridpane-$(cat /root/gridcreds/gridpane.uuid)-//g” | sed “s/-/./g”

## Remote Backups
* ```/usr/local/bin/gpbup2 domain.com -get-available-backups```

## Backup Configuration
* /var/www/site.url/logs/backups.env

## Backup Storage
* /opt/gridpane/backups/

## Backup Logs
* /var/www/site.url/logs/backups.env
* /var/log/gridpane.log
* /var/opt/gridpane/backups.log - Seems Empty.

# Security
## fail2ban
Setup fail2ban on server.
* gp stack -enable-fail2ban-jail wp-login 5 1200
Setup a site with fail2ban
* gp site {site.url} -enable-wp-fail2ban
Block User enumeration
* gp site {site.url} -configure-wp-fail2ban -block-user-enumeration
Enable server wide
*

# Maldet
## Installing
* gp stack maldet -install
## Log files
* /opt/gridpane/maldet-all-sites-report.ids
* /opt/gridpane/maldet-all-sites-scan.log
* /usr/local/maldetect/logs/event_log

# 7G Firewall
## Logs
* /var/www/{site.url}/logs/7g.log

# Post to Slack
* /usr/local/bin/gpmonitor <title> <data>

# Nginx
## Regenerate Nginx Config
* gp site domain.com -regenerate-nginx-configs --force

# Enable Debug Mode
* /usr/local/bin/gp site store.vitalbody.ca wp-debug-on

# Create Vanilla Nginx Config
* gp conf nginx generate https-vanilla site.com