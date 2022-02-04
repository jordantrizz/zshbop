# --
# PHP commands
# --

# - Init help array
typeset -gA help_php

# - phpinfo
help_php[phpinfo]='Generate phpinfo() file'
alias phpinfo="echo '<?php phpinfo() ?>' > phpinfo.php"

# - opcache
help_php[opcache]='Download opcache.php file for monitoring opcache usage.'
alias opcache="sudo curl -o opcache.php https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php"
