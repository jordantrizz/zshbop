# --
# PHP commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[php]='PHP related commands'

# - Init help array
typeset -gA help_php

# ---------------
# -- Bin Software
# ---------------
# -- cachetool.phar
help_php[cachetool.phar]='PHP OPCode Caching CLI Tool https://github.com/gordalina/cachetool'
help_php[phpstan.phar]='PHP Static Analysis and compatibility check.'
help_php[phan.phar]='A static analyzer. PHP 8 checker.'

# ------------
# -- Functions
# ------------

# -- phpinfo
help_php[php-info]='Generate phpinfo() file'
alias php-info="echo '<?php phpinfo() ?>' > phpinfo.php"

# -- opcache
help_php[php-opcache]='Download opcache.php file for monitoring opcache usage.'
alias php-opcache="sudo curl -o opcache.php https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php"

# -- php
help_php[php-strace]='strace php-fpm pools'
php-strace () {
	if [[ -z $1 ]]; then
		echo "Usage: php-strace <grep>"
		echo "Example: php-strace php-fpm or php-strace www"
		return
	fi
	echo "Starting strace on $1"
	strace -s 65555 -o php-fpm.strace-log -ttt -ff $(ps -auxwwf | grep "$1" | awk {' print $2 '} | paste -s | sed -e 's/\([0-9]\+\)/-p \1/g' -e 's/\t/ /g')
}

# -- php-install @@ISSUE what is this about?
help_php[php-install]='One liner for install PHP'

