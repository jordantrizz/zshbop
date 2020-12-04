# GridPane CLI Commands
*gp fix clear-cache - clear entire server cache

# MySQL
## MySQL Root Login
* gridenv/promethean.env
* gp mysql -get-pass root

## Setting MySQL Configuration
* gp stack mysql -max-connections 100 &&  
* gp stack mysql -innodb-buffer-pool-size 2048 && 
* gp stack mysql -innodb-buffer-pool-instances 2 && 
* gp mysql restart

# Set Default Site
* gp site {site.url} -set-nginx-default
## Default Site Redirect
<meta http-equiv="refresh" content="0; URL='https://site.com/?utm_source=gridpane&utm_medium=redirect&utm_campaign=default'" />

# Redis Cache Expiry
* gp stack nginx redis -site-cache-valid {accepted.value} {site.url}

# Clear Site Redis Full Page Cache
* gp fix cache cached site.com

# Suspend a Site
* gp site {site.url} -suspend
* Utilizes /var/www/holding.html so update this file if needed.

# Setup System Cron for WordPress
* gp site {site.url} -gpcron-on {minute.interval}

# Clear site cache
* gp fix cached eiexperience.com

# Change PHP Settings
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

## Logs
* /var/www/site.url/logs/backups.env
* /var/log/gridpane.log
* /var/opt/gridpane/backups.log - Seems Empty.