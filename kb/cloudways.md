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