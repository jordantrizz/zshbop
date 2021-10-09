# Popular Links
*[wpinfo.net - Gridpane Cheatsheet CLI](https://wpinfo.net/2021/05/13/gridpane-cli-cheatsheet/)

# GridPane CLI Commands
*gp fix clear-cache - clear entire server cache

# General
## Set Default Site
* gp site {site.url} -set-nginx-default
## Default Site Redirect
<meta http-equiv="refresh" content="0; URL='https://site.com/?utm_source=gridpane&utm_medium=redirect&utm_campaign=default'" />

## Suspend a Site
* gp site {site.url} -suspend
* Utilizes /var/www/holding.html so update this file if needed.

## Clear site cache
* gp fix cached eiexperience.com

# Advanced
## Setup System Cron for WordPress
* gp site {site.url} -gpcron-on {minute.interval}

# SSL
## PHPMyAdmin SSL
* gp site phpma -ssl-renewal

## Monit
* gp site monit -ssl-renewal

# MySQL
## MySQL Root Login
* gridenv/promethean.env
* gp mysql -get-pass root

## MySQL Configuration
* gp stack mysql -max-connections 100
* gp stack mysql -innodb-buffer-pool-size 2048
* gp stack mysql -innodb-buffer-pool-instances 2
* gp stack mysql -innodb-log-file-size 256
* gp stack mysql -slow-query-log 1
** MySQL slow query log output can be viewed in the following log: /var/log/mysql/slow.log
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
* /usr/local/bin/gpbup domain.com -get-available-backups
## Remote Backups
* /usr/local/bin/gpbup2 domain.com -get-available-backups
## Backup Configuration
* /var/www/site.url/logs/backups.env

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
## Log files
* /opt/gridpane/maldet-all-sites-report.ids
* /opt/gridpane/maldet-all-sites-scan.log
* /usr/local/maldetect/logs/event_log
