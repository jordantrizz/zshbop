---
title: Openlitespeed
description: "Knowledge base article on Openlitespeed. Also available in the shell as `kb openlitespeed`."
---

<!-- BEGIN GENERATED: kb-openlitespeed -->
* Get Version '''/usr/local/lsws/bin/openlitespeed -v'''
## Cache
* Server Configuration > Modules > Cache.

## Per Site PHP Overrides
* Edit vhost conf and add
```
phpIniOverride  {
 php_value error_log /home/dev.goodmorningleland.com/logs/dev.goodmorningleland.com.error_log
 php_flag display_startup_errors on
 php_flag display_errors on
}
```
* Edit PHP Worker Configuration

```
PHPRC=/home/domain.com/public_html
```
* Restart openlitespeed and kill lsphp
```
lswsctrl fullrestart;skill -9 lsphp
```

## Installing PECL Extensions
```
apt-get install lsphp74-dev lsphp74-pear
cd /usr/local/lsws/lsphp74/bin
pecl channel-update pecl.php.net
pear config-set temp_dir /root/tmp
pecl install timezonedb
```

## Notes

### Block WordPress xmlrpc.php via .htaccess
```
# Block WordPress xmlrpc.php requests
<IfModule mod_rewrite.c>
 RewriteRule xmlrpc - [F,L]
</IfModule>
```

---

*Generated from [`kb/openlitespeed.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/openlitespeed.md) by
`npm run gen:kb`. The shell shows the same article with `kb openlitespeed`.*

<!-- END GENERATED: kb-openlitespeed -->
