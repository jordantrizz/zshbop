# =============================================================================
# Core commands
# Example help: help_wordpress[wp]='Generate phpinfo() file'
# =============================================================================
_debug " -- Loading ${(%):-%N}"

# Init variables and arrays
help_files[core]='Core commands'
typeset -gA help_core
help_core[kb]='Knowledge Base'

# ===============================================
# -- os - return os
# ===============================================
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
  echo "\$ZSHBOP_TERMINAL: $ZSHBOP_TERMINAL"
  echo "-------------------"
  echo "\$OS_INSTALL_DATE: $OS_INSTALL_DATE | \$OS_INSTALL_METHOD: $OS_INSTALL_METHOD"
  echo "\$OS_INSTALL_DATE2: $OS_INSTALL_DATE2 | \$OS_INSTALL_METHOD2: $OS_INSTALL_METHOD2"
}

# ===============================================
# -- os - return os
# ===============================================
help_core[os-short]='Return OS (short format)'
function os-short () {
  local OUTPUT
  OUTPUT+="OS: $MACHINE_OS/${MACHINE_OS2}/$OSTYPE Flavour:${MACHINE_OS_FLAVOUR}/${MACHINE_OS_VERSION} Install Date: $OS_INSTALL_DATE"  
  if [[ $VMTYPE ]] then
    OUTPUT+=" VM: $VMTYPE" 
  fi
  OUTPUT+=" Terminal: $ZSHBOP_TERMINAL"
  echo $OUTPUT
}

# =============================================================================
# -- system
# =============================================================================
help_core[system]='System Information'
function system () {
    _loading "System Information"

    # -- OS specific motd
    _start_boot_timer "motd:os-short"
    _loading3 $(os-short)
    _finish_boot_timer "motd:os-short"

    # -- system details
    _start_boot_timer "motd:sysfetch"
    sysfetch-motd
    _finish_boot_timer "motd:sysfetch"

    # -- sysinfo
    _start_boot_timer "motd:cpu"
    _loading3 $(cpu 0 1)
    _finish_boot_timer "motd:cpu"
    _start_boot_timer "motd:mem"
    _loading3 $(mem)
    _finish_boot_timer "motd:mem"
    _start_boot_timer "motd:check-system"
    zshbop_check-system
    _finish_boot_timer "motd:check-system"
    echo ""
}

# ===============================================
# -- debug-zshbop-loading
# ===============================================
help_core[debug-zshbop-loading]='Debug the _loading function system-wide'
function debug-zshbop-loading () {
    echo "=== DEBUGGING ZSHBOP _loading FUNCTION SYSTEM-WIDE ==="
    echo ""
    
    echo "1. Environment Variables:"
    echo "   QUIET: '$QUIET'"
    echo "   ZB_LOG: '$ZB_LOG'"
    echo "   ZB_LOG_PATH: '$ZB_LOG_PATH'"
    echo "   ZB_LOG_FILE: '$ZB_LOG_FILE'"
    echo "   ZSHBOP_ROOT: '$ZSHBOP_ROOT'"
    echo ""
    
    echo "2. Log file status:"
    if [[ -f "$ZB_LOG" ]]; then
        echo "   ✓ Log file exists: $ZB_LOG"
        echo "   ✓ File permissions: $(ls -la "$ZB_LOG")"
        echo "   ✓ File size: $(du -h "$ZB_LOG" | cut -f1)"
        echo "   ✓ Directory permissions: $(ls -lad "$(dirname "$ZB_LOG")")"
    else
        echo "   ✗ Log file missing: $ZB_LOG"
        echo "   ✓ Directory exists: $(ls -lad "$(dirname "$ZB_LOG")" 2>/dev/null || echo "NO")"
    fi
    echo ""
    
    echo "3. Function definitions:"
    echo "   _loading type: $(type _loading 2>/dev/null || echo "NOT FOUND")"
    echo "   _loading2 type: $(type _loading2 2>/dev/null || echo "NOT FOUND")"
    echo ""
    
    echo "4. Shell and system info:"
    echo "   Shell: $SHELL"
    echo "   ZSH version: $ZSH_VERSION"
    echo "   OS: $(uname -s)"
    echo "   User: $(whoami)"
    echo "   Home: $HOME"
    echo ""
    
    echo "5. Testing basic components:"
    
    # Test process substitution
    echo "   Testing process substitution:"
    if echo "test" | tee >(cat > /dev/null) >/dev/null 2>&1; then
        echo "   ✓ Process substitution works"
    else
        echo "   ✗ Process substitution FAILED"
    fi
    
    # Test sed
    echo "   Testing sed:"
    if echo "test" | sed 's/^/[TEST] /' >/dev/null 2>&1; then
        echo "   ✓ sed works"
    else
        echo "   ✗ sed FAILED"
    fi
    
    # Test tee to file
    echo "   Testing tee to file:"
    local test_file="/tmp/zshbop_debug_$$"
    if echo "test" | tee "$test_file" >/dev/null 2>&1; then
        echo "   ✓ tee to file works"
        rm -f "$test_file"
    else
        echo "   ✗ tee to file FAILED"
    fi
    
    # Test complex pipe
    echo "   Testing complex pipe (like _loading uses):"
    if echo "test" | tee >(sed 's/^/[TEST] /' >> /tmp/zshbop_test_$$) >/dev/null 2>&1; then
        echo "   ✓ Complex pipe works"
        rm -f "/tmp/zshbop_test_$$"
    else
        echo "   ✗ Complex pipe FAILED"
    fi
    echo ""
    
    echo "6. Testing _loading function variants:"
    
    # Test with different QUIET values
    echo "   Testing with QUIET=0:"
    QUIET=0
    echo "Testing _loading" | tee >(sed 's/^/[DEBUG] /' >> ${ZB_LOG:-/tmp/debug.log})
    
    echo "   Testing with unset QUIET:"
    unset QUIET
    echo "Testing _loading unset" | tee >(sed 's/^/[DEBUG] /' >> ${ZB_LOG:-/tmp/debug.log})
    
    echo ""
    echo "7. Alternative _loading function (for testing):"
    echo "   You can try this alternative:"
    echo '   function _loading_alt () { echo "\$bg[yellow]\$fg[black] * \${@}\${RSC}"; echo "[LOAD] \$*" >> "\${ZB_LOG:-/tmp/alt.log}"; }'
}
