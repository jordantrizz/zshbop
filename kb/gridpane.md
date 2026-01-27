# Table of Contents
- [Table of Contents](#table-of-contents)
- [Popular Links](#popular-links)
- [GridPane CLI Commands](#gridpane-cli-commands)
  - [Set Default Site](#set-default-site)
  - [Default Site Redirect](#default-site-redirect)
  - [Suspend a Site](#suspend-a-site)
  - [Setup System Cron for WordPress](#setup-system-cron-for-wordpress)
  - [Check and Download Latest GridPane Scripts](#check-and-download-latest-gridpane-scripts)
  - [PHPMyAdmin SSL](#phpmyadmin-ssl)
  - [Unlock SSL Renewal Failures](#unlock-ssl-renewal-failures)
  - [Configure Nginx](#configure-nginx)
    - [Nginx Rate Limiting](#nginx-rate-limiting)
      - [Whitelist Page wp Zone](#whitelist-page-wp-zone)
      - [Update wp-login.php Rate Limiting](#update-wp-loginphp-rate-limiting)
        - [Directive: limit\_req\_zone](#directive-limit_req_zone)
        - [Directive: limit\_req](#directive-limit_req)
- [SSL](#ssl)
  - [SSL Logs](#ssl-logs)
- [Monit](#monit)
  - [Run Monit Check for SSL Renewals](#run-monit-check-for-ssl-renewals)
  - [Run Monit Check for MySQL](#run-monit-check-for-mysql)
  - [Change monit Alert and Restart for MySQL](#change-monit-alert-and-restart-for-mysql)
  - [Change monit Alert and Restart for Redis](#change-monit-alert-and-restart-for-redis)
- [MySQL](#mysql)
  - [MySQL Service Control](#mysql-service-control)
  - [MySQL Logins](#mysql-logins)
  - [MySQL Configuration](#mysql-configuration)
  - [MySQL Slow Query Log](#mysql-slow-query-log)
- [GridPane Fix Commands](#gridpane-fix-commands)
- [Redis](#redis)
  - [Redus Auth](#redus-auth)
- [Caching](#caching)
  - [Redis Page Cache](#redis-page-cache)
    - [Enable Redis Page Cache](#enable-redis-page-cache)
    - [Redis Cache Expiry](#redis-cache-expiry)
  - [FastCGI Cache](#fastcgi-cache)
    - [Enable FastCGI Cache](#enable-fastcgi-cache)
  - [Disable Cache](#disable-cache)
- [Object Cache](#object-cache)
  - [Change Redis maxmemory](#change-redis-maxmemory)
- [PHP](#php)
  - [Change PHP Settings](#change-php-settings)
  - [Update PHP memory per PHP version.](#update-php-memory-per-php-version)
  - [Update PHP memory per site.](#update-php-memory-per-site)
  - [Enable php-fpm slow log](#enable-php-fpm-slow-log)
  - [PHP FPM pm.max-requests](#php-fpm-pmmax-requests)
  - [PHP: Changing CLI PHP Version](#php-changing-cli-php-version)
- [Cache](#cache)
  - [Commands](#commands)
- [Backups](#backups)
  - [Local Backup Commands](#local-backup-commands)
  - [List local backup snapshots for sites.](#list-local-backup-snapshots-for-sites)
  - [Remote Backups](#remote-backups)
  - [Backup Configuration](#backup-configuration)
  - [Backup Storage](#backup-storage)
  - [Backup Logs](#backup-logs)
- [Security](#security)
  - [Additional Measures](#additional-measures)
  - [fail2ban](#fail2ban)
- [Maldet](#maldet)
  - [Installing](#installing)
  - [Log files](#log-files)
- [7G Firewall](#7g-firewall)
  - [Logs](#logs)
- [Post to Slack](#post-to-slack)
- [Nginx](#nginx)
  - [Regenerate Nginx Config](#regenerate-nginx-config)
- [Enable Debug Mode](#enable-debug-mode)
- [Create Vanilla Nginx Config](#create-vanilla-nginx-config)
- [GridPane Deployment Issues](#gridpane-deployment-issues)
  - [GCP](#gcp)
- [Notes](#notes)
  - [Check Caching](#check-caching)
    - [Redis](#redis-1)
    - [Nginx](#nginx-1)


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

## Setup System Cron for WordPress
* gp site {site.url} -gpcron-on {minute.interval}

## Check and Download Latest GridPane Scripts
* /usr/local/bin/gpupdate

## PHPMyAdmin SSL
* gp site phpma -ssl-renewal

## Unlock SSL Renewal Failures
Below is an example using gridpane.com
```
cd cd /var/www/gridpane.com/logs
rm examplewebsite.com-ssl_fail-1.date
rm examplewebsite.com-ssl_fail-2.date
examplewebsite.com-ssl_fail-3.date
```

## Configure Nginx
https://gridpane.com/kb/configure-nginx/

### Nginx Rate Limiting

#### Whitelist Page wp Zone
* Edit /etc/nginx/extra.d/whitelist-request-uri-rate-limit-whitelist.conf
```
~my-request-uri.php 0;
```


#### Update wp-login.php Rate Limiting
##### Directive: limit_req_zone
* Config location: /etc/nginx/common/limits.conf
* Context: http
*  Unit: MB (key store size) and Rate (requests/s)
* Default value: 10 3
* Accepted values: integers
* Zone One: Defaults to a 10 megabyte key limit with an average request processing rate for that cannot exceed 3 request per second. This zone is used to protect the WordPress login URL primarily.
```
gp stack nginx limits -req-zone-one {store.size.mb} {req.per.sec}
```

##### Directive: limit_req
* Config location: /etc/nginx/common/{site.url}-wpcommon.conf
* Context: server
* Accepted values: integer, fqdn
* Zone One: Defaults to a 1 request burst queue when the rate limit of 1 request per second has been exceeded. This zone protects the wp-login url. We do not recommend adjusting this zone burst. Consider it your login guard.
```
gp stack nginx limits -site-zone-one-burst {queue.size} {site.url}
```

# SSL
## SSL Logs
*  /opt/gridpane/certbot.monitoring.log
*  /opt/gridpane/acme.monitoring.log


# Monit
Change all monit settings via gpmonit https://gridpane.com/kb/configure-monit-with-gp-cli/
## Run Monit Check for SSL Renewals
* gp site monit -ssl-renewal
## Run Monit Check for MySQL
* gpmonit mysql
## Change monit Alert and Restart for MySQL
```
gpmonit mysql -mem-high-mb 900 -mem-restart-mb 1024
```
## Change monit Alert and Restart for Redis
```
gpmonit redis \
-cpu-warning-percent 120 -cpu-warning-cycles 10 \
-cpu-restart-percent 160 -cpu-restart-cycles 5 \
-mem-high-mb 907 -mem-high-cycles 10 \
-mem-restart-mb 1207 -mem-restart-cycles 10
```

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
The default values are specified below, however the full list is at https://gridpane.com/kb/configure-mysql/

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

## MySQL Slow Query Log
* gp stack mysql -slow-query-log 0
* gp stack mysql -long-query-time 0 

MySQL slow query log output can be viewed in the following log: /var/log/mysql/slow.log

# GridPane Fix Commands
* Reset file permissions ```gpfix perms site.com```
* Clear single site cache ```gp fix cache site.com```
* Clear all sites on server cache ``` gp fix cache```


# Redis
## Redus Auth
To be able to interact with GridPane's redis instance, you need to auth due to protected-mode being enabled. The password is stored in /opt/gridpane/object.auth

# Caching
## Redis Page Cache
### Enable Redis Page Cache
* gp site {site.url} -redis-cache -ttl 2592000
### Redis Cache Expiry
* gp stack nginx redis -site-cache-valid {accepted.value} {site.url}

## FastCGI Cache
### Enable FastCGI Cache
* gp site {site.url} -fastcgi-cache -ttl 1

## Disable Cache
* gp site {site.url} -cache-off

# Object Cache
## Change Redis maxmemory
* https://gridpane.com/kb/configure-redis/
The below example will set the redis maxmemory to 300MB
```
gp stack redis -max-memory 300

```

# PHP
## Change PHP Settings
* https://gridpane.zendesk.com/hc/en-us/articles/360038296712-Configure-PHP
## Update PHP memory per PHP version.
* gp stack php 7.4 -mem-limit 512 -no-reload &&
## Update PHP memory per site.
* gp stack php -site-mem-limit 512 test.com
## Enable php-fpm slow log
* gp stack php -site-slowlog true site.url
* gp stack php -site-slowlog-timeout 5 site.url
* gp stack php -site-slowlog-trace-depth 15 site.url
## PHP FPM pm.max-requests
* gp stack php site-pm-max-requests 5000 site.url

## PHP: Changing CLI PHP Version
* System Wide - `update-alternatives --config php`
* Per User Ubuntu 24 chroot) - cp /usr/local/bin
* Per User (Ubuntu 24 chroot Litespeed) - `cp /usr/bin/php8.1 /opt/gridpane/chroot/bin/php`

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
* /opt/gridpane/last-restore.log
* /opt/gridpane/gridpane.log
* /opt/gridpane/restore.log

# Security
## Additional Measures
* Disable xmlrpc ```gp site <site> -disable-xmlrpc```
## fail2ban
* Setup fail2ban on server. ```gp stack -enable-fail2ban-jail wp-login 5 1200```
* Setup a site with fail2ban ```gp site {site.url} -enable-wp-fail2ban```
* Block User enumeration ```gp site {site.url} -configure-wp-fail2ban -block-user-enumeration```


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
* 'gp monitor SYS_SWAP_MEM 75 warning'

# Nginx
## Regenerate Nginx Config
* gp site domain.com -regenerate-nginx-configs --force

# Enable Debug Mode
* /usr/local/bin/gp site store.vitalbody.ca wp-debug-on

# Create Vanilla Nginx Config
* gp conf nginx generate https-vanilla site.com

# GridPane Deployment Issues
## GCP
1. Install full Ubuntu
   * ```apt-get install -y ubuntu-server```
2. Ensure that GPC firewall rules allow tcp port 11371 ingress

# Notes

## Check Caching
### Redis
```
X-Grid-SRCache-Fetch HIT | MISS | BYPASS
HIT means the website is cached.

MISS means this page hadn’t been cached yet as it’s the first time it’s been visited since either the cache has been activated or cleared -on reload it should say HIT.

BYPASS means this page has been excluded and will never be cached.
```
### Nginx
```
X-Grid-Cache HIT | MISS | BYPASS | STALE

HIT means the website is cached.

MISS means this page hadn’t been cached yet as it’s the first time it’s been visited since either the cache has been activated or cleared -on reload it should say HIT.

BYPASS means this page has been excluded and will never be cached.

STALE means your browser’s cache has expired. This will be common with FastCGI as the cache refreshes every second by default. This still means that caching is taking place on your server.
```