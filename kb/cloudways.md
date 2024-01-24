# cloudways
## Secure Shell
### Setup wp-cli
Sometimes wp-cli is out of date
```
export WP_CLI_PACKAGES_DIR=$HOME/tmp
export PATH=$PATH:$HOME/tmp/bin
cd $HOME/tmp/bin
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar wp
alias wp='$HOME/tmp/bin/wp'
wp cli info
```

## wp-salts.php
Cloudways puts the WordPress salts into a wp-salts file. But this causes issues with wp-cli
```
https://feedback.cloudways.com/forums/203824-service-improvement/suggestions/42335206-add-salt-in-wp-config-php-instead-of-wp-salt-php
```
To fix the issue, updated the line in wp-config.php to include the wp-salts.php file with __DIR__
```
require(__DIR__ . '/wp-salts.php');
```