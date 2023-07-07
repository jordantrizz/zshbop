# PHP API Versions to Versions
* 20190902 ->  7.4.33
* 20200930 -> 8.0.29

# PHP Timezones
* https://www.php.net/manual/en/timezones.php

# PHP Performance Tweaking
## PHP 8.0
* https://haydenjames.io/php-8-compatibility-check-and-performance-tips/
### Enable JIT
PHP JIT is implemented as part of OPcache. You should already have OPcache enabled via php.ini/opcache.ini:

```opcache.enable=1```

Next, you’ll want to add the following to enable JIT:

```opcache.jit_buffer_size=100M```

When enabled (remember to restart PHP), the native code of PHP files is stored in an additional region of OPcache’s shared memory.

### Enable realpath_cache
For high-traffic web servers running PHP, you can squeeze out additional throughput by setting PHP realpath_cache_size ‘correctly.’
```
realpath_cache_size = 256k
realpath_cache_ttl = 300
```

### MySQL Collect Statistics
Check your php.ini and make sure on your production servers, both of these settings mysqlnd.collect_statistics and mysqlnd.collect_memory_statistics are disabled. It should always be disabled unless you have a specific reason to enable it. You can view MySQL run-time statistics using the MySQL command line (ex. show status;). Also related to MySQL, depending on your scripts, you can set up PHP Redis or Memcached to reduce MySQL queries.
```
mysqlnd.collect_statistics = Off
mysqlnd.collect_memory_statistics = Off
```

### Output Buffering
The recommended setting for this is Off or 4096, depending on your application. For example, if the HTML head contains CSS or JS (not a good practice), the browser could be paralleling those downloads with output_buffering enabled.
```
output_buffering = 4096
```

# opcode cache Tweaking
* https://haydenjames.io/php-benchmarks-opcache-performance-tweaks/
## OPcache Tools
* https://github.com/gordalina/cachetool
* https://github.com/amnuts/opcache-gui

## Good Basics
```
opcache.memory_consumption=256
opcache.validate_timestamps=1
opcache.interned_strings_buffer=64
opcache.max_accelerated_files=32500
opcache.save_comments=1
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
```

## realpath_cache_size
* https://haydenjames.io/set-monitor-phps-realpath_cache_size-correctly/

Create a .php file and run this via a browser

```
<?php
var_dump(realpath_cache_size());
?>
```

It will return something like this

```
int(178356)
```

As per the article.

```
So in my case I’m using about 178KB of realpath_cache. I had realpath_cache_size set to 4M and so I was able to reduce it to “realpath_cache_size = 1M” in php.ini. The realpath_cache_size default was increased x256 frm 16K to 4M (4096K).
```

Set the realpath_cache_size

```
realpath_cache_size = 256k
realpath_cache_ttl = 300
```

# Code Compatiability
## Checking PHP8
### PHP Code Sniffer
1. Download https://github.com/PHPCompatibility/PHPCompatibility release to a directory
2. Set path with PHP Code Sniffer
```
./phpcs.phar --config-set installed_paths /root/bin/PHPCompatibility-9.3.5
```
3. Run PHP Code Sniffer skip warnings
./phpcs.phar -p /var/www/vitalbody.ca/htdocs/wp-content/plugins/fluent-smtp --standard=PHPCompatibility --runtime-set testVersion 8.0 -n

# Run PHP Code via CLI
```
php -r "echo gethostbyaddr('127.0.0.1');"
```