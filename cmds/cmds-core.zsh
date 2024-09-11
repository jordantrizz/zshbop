# ==============================================
# Core commands
# Example help: help_wordpress[wp]='Generate phpinfo() file'
# ==============================================
_debug " -- Loading ${(%):-%N}"

# Init variables and arrays
help_files[core]='Core commands'
typeset -gA help_core
help_core[kb]='Knowledge Base'

# =====================================
# -- os - return os
# =====================================
help_core[os]='Return OS'
function os () {
  echo "\$MACHINE_OS: $MACHINE_OS | \$MACHINE_OS2: $MACHINE_OS2"
  echo "\$MACHINE_OS_FLAVOUR: $MACHINE_OS_FLAVOUR | \$MACHINE_OS_VERSION:$MACHINE_OS_VERSION"
  echo "-------------------"
  echo "\$OSTYPE: $OSTYPE"
  if [[ $VMTYPE ]] then
    echo "\$VMTYPE: $VMTYPE"
  else
    echo "\$VMTYPE: Not set"
  fi
  echo "-------------------"
  echo "\$OS_INSTALL_DATE: $OS_INSTALL_DATE | \$OS_INSTALL_METHOD: $OS_INSTALL_METHOD"
  echo "\$OS_INSTALL_DATE2: $OS_INSTALL_DATE2 | \$OS_INSTALL_METHOD2: $OS_INSTALL_METHOD2"
}

# =====================================
# -- os - return os
# =====================================
help_core[os]='Return OS'
function os-short () {
  local OUTPUT
  OUTPUT+="OS: $MACHINE_OS/${MACHINE_OS2}/$OSTYPE Flavour:${MACHINE_OS_FLAVOUR}/${MACHINE_OS_VERSION} Install Date: $OS_INSTALL_DATE"  
  if [[ $VMTYPE ]] then
    OUTPUT+=" VM: $VMTYPE" 
  fi 
  echo $OUTPUT
}

# ====================================================================================================
# -- system
# ====================================================================================================
help_core[system]='System Information'
function system () {
    _loading "System Information"

    # -- OS specific motd
    _loading3 $(os-short)   

    # -- system details
    sysfetch-motd

    # -- sysinfo
    _loading3 $(cpu 0 1)    
    _loading3 $(mem)
    zshbop_check-system
    echo ""
}