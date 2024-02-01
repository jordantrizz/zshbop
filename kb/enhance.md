# Enhance
## Common File Locations
* Site Logs: /var/local/enhance/webserver_logs/
* Litespeed Error Log: /var/local/enhance/litespeedlogs/error.log
* Litespeed Configuration: /var/local/enhance/litespeed

# Common CLI Commands
## Control Panel
* appcd-cli 8.8.8.8 change-webserver lite-speed - Change webserver to LiteSpeed, rebuilds docker container.

# Common Issues
## wp-cli as root
* apt-get install -y --no-install-recommends php-cli php-mysql
* Edit /etc/php/8.1/cli/php.ini
```
mysqli.default_socket = /var/local/enhance/mysqlcd-run/mysqld.sock
```
