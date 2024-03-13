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