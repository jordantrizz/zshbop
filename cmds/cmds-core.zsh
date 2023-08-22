# ==============================================
# Core commands
# Example help: help_wordpress[wp]='Generate phpinfo() file'
# ==============================================
_debug " -- Loading ${(%):-%N}"

# Init variables and arrays
help_files[core]='Core commands'
typeset -gA help_core
help_core[kb]='Knowledge Base'

# -- os - return os
help_core[os]='Return OS'
function os () {
  echo "\$MACHINE_OS: $MACHINE_OS | \$MACHINE_OS2: $MACHINE_OS2"
  echo "\$MACHINE_OS_FLAVOUR: $MACHINE_OS_FLAVOUR | \$MACHINE_OS_VERSION:$MACHINE_OS_VERSION"
  echo "\$OSTYPE: $OSTYPE"
}



