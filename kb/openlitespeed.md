# Common Commands
* Get Version '''/usr/local/lsws/bin/openlitespeed -v'''
# Cache
* Server Configuration > Modules > Cache.

# Per Site PHP Overrides
* Edit vhost conf and add
```
phpIniOverride  {
 php_value error_log /home/dev.goodmorningleland.com/logs/dev.goodmorningleland.com.error_log
 php_flag display_startup_errors on
 php_flag display_errors on
}
```