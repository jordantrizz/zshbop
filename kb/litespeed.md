# Litespeed
## Server Control
* ```lswsctrl```

## Server Status
* /tmp/lshttpd/.rtreport

## PHP Process Mode
* https://www.litespeedtech.com/support/wiki/doku.php/litespeed_wiki:php:process-mode?fbclid=IwAR3JeoNcDcQ9MT_rEzdzR2ri1Mcqzc0Nz4QntL2U8IitkJOqEMt3gRZF5kI
* ProcessGroup Mode default and best overall.

## Quick Fixes
### Scheduled Posts not Triggering
* Turn off WP-admin cache in Object caching, in the exclude section, add this to query string "doing_wp_cron"

## Per User PHP


## Install xdebug
### Install Pear for PHP 8.1 (Extra Step)
```
cd /usr/local/lsws/lsphp81/bin
wget http://pear.php.net/go-pear.phar
php go-pear.phar
```
### Script to Install xdebug
```
EXTENSION="xdebug"
PHP_VER_INSTALL=(81)
#PHP_VER_INSTALL=(81 80 74 73 72)
#PHP_VER_INSTALL=($(ls -1 /usr/local/lsws/ |grep lsphp | sed 's/lsphp//g'))
for phpver in $PHP_VER_INSTALL; do
    echo "Installing xdebug for PHP ${phpver}"
    php_ini="/usr/local/lsws/lsphp${phpver}/etc/php/$(echo $phpver | sed 's/^\(.\{1\}\)/\1./')/litespeed/php.ini"
    echo "php_ini: ${php_ini}"
    if [[ -f /usr/local/lsws/lsphp${phpver}/bin/pecl ]]; then
        echo "pecl exists"
    else
        echo "Error: pecl does not exist in /usr/local/lsws/lsphp${phpver}/bin/pecl"
        exit 1        
    fi
    
    echo "Installing xdebug for PHP ${phpver} using pecl"
    /usr/local/lsws/lsphp${phpver}/bin/pecl install ${EXTENSION}
    
    echo "Writing xdebug config to ${php_ini}"
    echo "zend_extension=${EXTENSION}.so" >> ${php_ini}
    echo "xdebug.mode=debug" >> ${php_ini}
    echo "xdebug.remote_enable=1" >> ${php_ini}
    echo "xdebug.remote_connect_back=1" >> ${php_ini}
    echo "xdebug.remote_port=9000" >> ${php_ini}
    echo "xdebug.client_port=9000" >> ${php_ini}
done

if [[ -f /usr/local/lsws/bin/lswsctrl ]]; then
    echo "Restarting LiteSpeed"
    /usr/local/lsws/bin/lswsctrl restart
else
    echo "Error: lswsctrl does not exist in /usr/local/lsws/bin/lswsctrl, restart manually"
    exit 1
fi
```