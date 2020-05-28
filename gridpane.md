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
