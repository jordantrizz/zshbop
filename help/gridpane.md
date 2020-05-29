# GridPane CLI Commands
*gp fix clear-cache - clear entire server cache

# Misc
## MySQL Root Login
* gridenv/promethean.env
* gp mysql -get-pass root

# Default Site Redirect
<meta http-equiv="refresh" content="0; URL='https://site.com/?utm_source=gridpane&utm_medium=redirect&utm_campaign=default'" />

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