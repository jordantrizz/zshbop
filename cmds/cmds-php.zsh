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

# - phpinfo
help_php[php-info]='Generate phpinfo() file'
alias php-info="echo '<?php phpinfo() ?>' > phpinfo.php"

# - opcache
help_php[php-opcache]='Download opcache.php file for monitoring opcache usage.'
alias php-opcache="sudo curl -o opcache.php https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php"
