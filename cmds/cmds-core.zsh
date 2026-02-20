# ==============================================
# Core commands
# Example help: help_wordpress[wp]='Generate phpinfo() file'
# ==============================================
_debug " -- Loading ${(%):-%N}"

# Init variables and arrays
help_files[core]='Core commands'
typeset -gA help_core
help_core[kb]='Knowledge Base'
help_core[antidote-debug]='Generate antidote/auto-ls debug report'

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
  echo "\$ZSHBOP_TERMINAL: $ZSHBOP_TERMINAL"
  echo "-------------------"
  echo "\$OS_INSTALL_DATE: $OS_INSTALL_DATE | \$OS_INSTALL_METHOD: $OS_INSTALL_METHOD"
  echo "\$OS_INSTALL_DATE2: $OS_INSTALL_DATE2 | \$OS_INSTALL_METHOD2: $OS_INSTALL_METHOD2"
}

# =====================================
# -- os - return os
# =====================================
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

# ==================================================
# -- debug-zshbop-loading
# ==================================================
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

# ==================================================
# -- mise-uvx-check
# ==================================================
help_core[mise-uvx-check]='Check uvx symlink health for mise integration'
function mise-uvx-check () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help

    if [[ -n $opts_help ]]; then
        echo "Usage: mise-uvx-check [-h|--help]"
        return 0
    fi

    local link_path
    link_path="$HOME/bin/uvx"

    local expected_target
    expected_target="$HOME/.local/share/mise/shims/uvx"

    if (( $+commands[mise] )); then
        _success "mise detected: $(command -v mise)"
    else
        _warning "mise not found in PATH"
        return 1
    fi

    local resolved_uvx
    resolved_uvx="$(mise which uvx 2>/dev/null)"
    if [[ -n "$resolved_uvx" ]]; then
        _success "mise reports uvx: $resolved_uvx"
    else
        _warning "mise does not have uvx active (try: mise use -g uv@latest)"
        return 1
    fi

    if [[ -L "$link_path" ]]; then
        local current_target
        current_target="$(readlink "$link_path" 2>/dev/null)"
        if [[ "$current_target" == "$expected_target" ]]; then
            _success "uvx symlink healthy: $link_path -> $current_target"
        else
            _warning "uvx symlink points to $current_target (expected $expected_target)"
            return 1
        fi
    elif [[ -e "$link_path" ]]; then
        _warning "$link_path exists but is not a symlink"
        return 1
    else
        _warning "$link_path is missing"
        return 1
    fi

    if (( $+commands[uvx] )); then
        _success "uvx command resolves: $(command -v uvx)"
        uvx --version >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            _success "uvx runtime check passed"
            return 0
        fi
        _warning "uvx command found but failed to execute"
        return 1
    fi

    _warning "uvx command not found in PATH"
    return 1
}

# ==================================================
# -- antidote-debug
# ==================================================
function antidote-debug () {
    local -a opts_help opts_output
    zparseopts -D -E -- h=opts_help -help=opts_help o:=opts_output -output:=opts_output

    if [[ -n $opts_help ]]; then
        echo "Usage: antidote-debug [-h|--help] [-o|--output <path>]"
        return 0
    fi

    local timestamp output_file output_arg output_dir plugin_file filter_pattern
    timestamp="$(date +%Y%m%d-%H%M%S 2>/dev/null)"
    [[ -z "$timestamp" ]] && timestamp="unknown-time"

    output_file="${ZSHBOP_ROOT}/debug/antidote-debug-${timestamp}.log"

    if [[ -n ${opts_output[-1]} ]]; then
        output_arg="${opts_output[-1]}"
        if [[ "$output_arg" == --output=* ]]; then
            output_arg="${output_arg#--output=}"
        fi
        if [[ "$output_arg" != "-o" && "$output_arg" != "--output" && -n "$output_arg" ]]; then
            output_file="$output_arg"
        fi
    fi

    output_dir="$(dirname "$output_file" 2>/dev/null)"
    if [[ -n "$output_dir" ]]; then
        mkdir -p "$output_dir" 2>/dev/null || true
    fi

    if ! : > "$output_file" 2>/dev/null; then
        _error "antidote-debug: unable to write output file $output_file"
        return 1
    fi

    plugin_file="${ZSHBOP_ROOT}/.zsh_plugins.txt"
    filter_pattern='auto-ls|autosuggestions|syntax-highlighting|ohmyzsh|H-S-MW'

    {
        echo "=== antidote-debug report ==="
        echo ""
        echo "1) Runtime info"
        echo "date: $(date 2>/dev/null || echo "WARNING: date unavailable")"
        echo "host: $(hostname 2>/dev/null || echo "WARNING: hostname unavailable")"
        echo "user: $(whoami 2>/dev/null || echo "WARNING: whoami unavailable")"
        echo "pwd: $PWD"
        echo "shell: $SHELL"
        echo "zsh version: $ZSH_VERSION"
        echo ""
        echo "2) Env"
        echo "TERM_PROGRAM=${TERM_PROGRAM:-}"
        echo "VSCODE_IPC_HOOK_CLI=${VSCODE_IPC_HOOK_CLI:-}"
        echo "ZSHBOP_RELOAD=${ZSHBOP_RELOAD:-}"
        echo "ZSHBOP_INITIALIZED=${ZSHBOP_INITIALIZED:-}"
        echo "ZSHBOP_TERMINAL=${ZSHBOP_TERMINAL:-}"
        echo ""
        echo "3) zshbop vars"
        echo "ZSHBOP_PLUGIN_MANAGER=${ZSHBOP_PLUGIN_MANAGER:-}"
        echo "ZSHBOP_ROOT=${ZSHBOP_ROOT:-}"
        echo "ZB_LOG=${ZB_LOG:-}"
        echo ""
        echo "4) .zsh_plugins.txt with line numbers"
        if [[ -f "$plugin_file" ]]; then
            if (( $+commands[nl] )); then
                nl -ba "$plugin_file"
            elif (( $+commands[awk] )); then
                awk '{printf "%6d  %s\\n", NR, $0}' "$plugin_file"
            else
                echo "WARNING: nl/awk unavailable, showing raw file"
                cat "$plugin_file" 2>/dev/null || echo "WARNING: unable to read $plugin_file"
            fi
        else
            echo "WARNING: missing file $plugin_file"
        fi
        echo ""
        echo "5) antidote checks"
        echo "whence -a antidote:"
        whence -a antidote 2>/dev/null || echo "WARNING: whence failed for antidote"
        if (( $+commands[antidote] )); then
            echo "antidote home:"
            antidote home 2>/dev/null || echo "WARNING: antidote home failed"
            echo "antidote list:"
            antidote list 2>/dev/null || echo "WARNING: antidote list failed"
        else
            echo "WARNING: antidote command not found"
        fi
        echo ""
        echo "6) antidote load excerpt"
        if [[ -f "$plugin_file" ]]; then
            grep -inE "$filter_pattern" "$plugin_file" 2>/dev/null || echo "WARNING: no matches in $plugin_file"
        else
            echo "WARNING: missing file $plugin_file"
        fi
        if (( $+commands[antidote] )) && [[ -f "$plugin_file" ]]; then
            antidote load < "$plugin_file" 2>/dev/null | grep -inE "$filter_pattern" 2>/dev/null || echo "WARNING: no matches in antidote load output"
        elif (( $+commands[antidote] )); then
            echo "WARNING: missing file $plugin_file, cannot inspect antidote load output"
        else
            echo "WARNING: antidote command not found, cannot inspect antidote load output"
        fi
        echo ""
        echo "7) auto-ls checks"
        echo "AUTO_LS_CHPWD=${AUTO_LS_CHPWD:-}"
        if typeset -p AUTO_LS_COMMANDS >/dev/null 2>&1; then
            typeset -p AUTO_LS_COMMANDS
        else
            echo "WARNING: AUTO_LS_COMMANDS not set"
        fi
        echo "whence -f _detect_ls:"
        whence -f _detect_ls 2>/dev/null || echo "WARNING: _detect_ls not found"
        echo "whence -f auto-ls-color:"
        whence -f auto-ls-color 2>/dev/null || echo "WARNING: auto-ls-color not found"
        echo "alias ls:"
        alias ls 2>/dev/null || echo "WARNING: alias ls not set"
        echo ""
        echo "8) key/widget/hook checks"
        if [[ -o interactive ]]; then
            echo "bindkey '^M':"
            bindkey '^M' 2>/dev/null || echo "WARNING: bindkey '^M' failed"
            echo "zle -lL accept-line:"
            zle -lL accept-line 2>/dev/null || echo "WARNING: zle -lL accept-line failed"
            echo "zle -lL auto-ls:"
            zle -lL auto-ls 2>/dev/null || echo "WARNING: zle -lL auto-ls failed"
            echo "zle matches (accept-line|auto-ls|autosuggest):"
            if zle -la >/dev/null 2>&1; then
                zle -la 2>/dev/null | grep -iE 'accept-line|auto-ls|autosuggest' || echo "WARNING: no zle matches found"
            else
                echo "WARNING: zle not available"
            fi
            echo ""
            echo "9) widget owner analysis"
            local accept_line_widget auto_ls_widget
            accept_line_widget="$(zle -lL accept-line 2>/dev/null | awk '{print $4}')"
            auto_ls_widget="$(zle -lL auto-ls 2>/dev/null | awk '{print $4}')"

            echo "accept-line widget target: ${accept_line_widget:-UNKNOWN}"
            echo "auto-ls widget target: ${auto_ls_widget:-UNKNOWN}"

            if [[ -n "$accept_line_widget" ]]; then
                echo "whence -f ${accept_line_widget}:"
                whence -f "$accept_line_widget" 2>/dev/null || echo "WARNING: could not resolve $accept_line_widget"
            fi

            if [[ -n "$auto_ls_widget" ]]; then
                echo "whence -f ${auto_ls_widget}:"
                whence -f "$auto_ls_widget" 2>/dev/null || echo "WARNING: could not resolve $auto_ls_widget"
            fi

            if [[ -n "$accept_line_widget" && "$accept_line_widget" != "auto-ls" && "$accept_line_widget" != "$auto_ls_widget" ]]; then
                echo "WARNING: accept-line is not directly bound to auto-ls"
                echo "WARNING: another plugin likely owns Enter and may bypass auto-ls"
            fi

            echo "functions likely affecting Enter/widgets:"
            whence -f _zsh_ai_accept_line _zsh_autosuggest_bound_1_auto-ls autosuggest-accept 2>/dev/null || true
        else
            echo "WARNING: non-interactive shell; skipping bindkey/zle checks"
        fi
        if typeset -p chpwd_functions >/dev/null 2>&1; then
            typeset -p chpwd_functions
        else
            echo "WARNING: chpwd_functions not set"
        fi
    } >> "$output_file" 2>&1

    _success "antidote-debug report written to $output_file"
    return 0
}
