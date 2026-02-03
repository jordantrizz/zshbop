# =============================================================================
# -- WSL commands
# =============================================================================
_debug " -- Loading ${(%):-%N}"
help_files[wsl]='Windows Subsystem for Linux commands'
typeset -gA help_wsl

# =============================================================================
# -- Aliases
# ===============================================
# -- traceroute - fixes WSL traceroute command
alias traceroute="sudo traceroute -M icmp"

# ===============================================
# -- _wsl_get_windows_user - Helper function to get Windows username
# ===============================================
function _wsl_get_windows_user () {
	local win_user=""
	
	# Try cmd.exe first
	if [[ -x /mnt/c/Windows/System32/cmd.exe ]]; then
		win_user=$(/mnt/c/Windows/System32/cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n' | tr -d '[:space:]')
	fi
	
	# Fallback to powershell if cmd.exe failed or returned empty
	if [[ -z "$win_user" ]]; then
		win_user=$(powershell.exe '$env:UserName' 2>/dev/null | tr -d '\r\n' | tr -d '[:space:]')
	fi
	
	# Validate the user folder exists before returning
	if [[ -n "$win_user" && -d "/mnt/c/Users/$win_user" ]]; then
		echo "$win_user"
	fi
}

# ===============================================
# -- Run Commands
# --
# -- These commands run on WSL startup
# ===============================================
# -- init_wsl
init_wsl () {
	_debug " -- Running init_wsl"
	
	# Set global WINDOWS_USER variable for all WSL functions
	export WINDOWS_USER=$(_wsl_get_windows_user)
	if [[ -z "$WINDOWS_USER" ]]; then
		_warning "Could not determine Windows username - some WSL features may not work"
	else
		_debug "Windows username: $WINDOWS_USER"
	fi
	
	wsl-fixes
	wsl-screen-fix
	wsl-backupwtc 1
	wsl-shortcuts
	init_log
	wsl-paths
	wsl-check-wslu
}

# =============================================================================
# -- Functions
# =============================================================================

# ===============================================
# -- wsl-fixes
# ===============================================
help_wsl[wsl-fixes]='Fix issues under WSL'
function wsl-fixes () {
	# -- Fix traceroute on WSL
	_cmd_exists traceroute
	if [[ $? -eq 0 ]]; then
		_debug " -- traceroute already installed"
	else
		_debug " -- Installing traceroute"
		sudo apt-get update
		sudo apt install inetutils-traceroute
		sudo apt install traceroute
	fi
}

# ===============================================
# -- wsl-backupwtc 
# ===============================================
help_wsl[wsl-backupwtc]='Backup Windows Terminal configuration.'
wsl-backupwtc () {
	if [[ -z "$WINDOWS_USER" ]]; then
		_error "WINDOWS_USER not set, cannot backup Windows Terminal config"
		return 1
	fi
	local WT_SOURCE="$(echo /mnt/c/Users/$WINDOWS_USER/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json)"
	local WT_DEST="$ZSHBOP_TEMP/wt-settings.json"
	local QUEIT=${1:=0}		
	local OUTPUT=""

	OUTPUT+="Copying Windows Terminal settings - "	
	if [[ ! -d "/mnt/c" ]]; then
		_error "/mnt/c does not exist, is WSL installed?"
		return 1
	fi
	
	# -- Checking if Windows Terminal settings.json exists"
	if [[ ! -f $WT_SOURCE ]]; then
		_error "Windows Terminal config not found at $WT_SOURCE "
		return 1
	fi

	# -- Check if temp folder exists
	if [[ ! -d "$ZSHBOP_TEMP" ]]; then
		_error "Temp folder $ZSHBOP_TEMP doesn't exist"
		return 1
	fi

	# -- Check if settings.json exists and see if source is newer	
	if [[ -f $WT_DEST ]]; then		
		if [[ $WT_SOURCE -nt $WT_DEST ]]; then
			OUTPUT+="Source is newer, backing up"
			cp $WT_SOURCE $WT_DEST
			OUTPUT+="backup completed at $ZSHBOP_TEMP/settings.json"
		else
			OUTPUT+="Source is not newer, skipping backup."			
		fi
	else
		OUTPUT+="No backup of settings.json found, backing up"		
		cp $WT_SOURCE $WT_DEST
		OUTPUT+="backup completed at $ZSHBOP_TEMP/settings.json"
	fi
	
	[[ $QUEIT == 0 ]] && _loading3 "$OUTPUT"	
}

# ===============================================
# -- check_diskspace_wsl
# ===============================================
help_wsl[wsl-check-diskspace]='Check disk space under WSL'
function wsl-check-diskspace () {
    # -- Check disk space
    if [[ $1 == "show" ]]; then
        _error "Checking disk space for WSL not implemented yet."
    else
        _error "Checking disk space for WSL not implemented yet."
    fi
    
}

# ===============================================
# -- wsl-shortcuts
# ===============================================
help_wsl[wsl-shortcuts]='Create Downloads and Desktop shortcuts for WSL'
function wsl-shortcuts () {
	local OUTPUT="" DO=0 OUTPUT_FULL=""
	local DOWNLOAD_FOLDER DESKTOP_FOLDER
	
	if [[ -z "$WINDOWS_USER" ]]; then
		_warning "WINDOWS_USER not set, skipping shortcut creation"
		return 1
	fi
	# -- Create shortcuts
	
	# -- Check to see if Downloads folder exists
	DOWNLOAD_FOLDER="/mnt/c/Users/$WINDOWS_USER/Downloads"
	[[ ! -d "$DOWNLOAD_FOLDER" ]] && { _warning "Windows Downloads folder $DOWNLOAD_FOLDER not found, skipping shortcut creation"; return 1; }
	# Check if Downloads folder exists as symlink
	if [[ ! -L "$HOME/Downloads" ]]; then
		ln -s /mnt/c/Users/$WINDOWS_USER/Downloads ~/Downloads	
		OUTPUT+="$HEADER Created Downloads shortcut."
		DO=1
	fi
	# -- Create Desktop shortcut
	DESKTOP_FOLDER="/mnt/c/Users/$WINDOWS_USER/Desktop"
	[[ ! -d "/mnt/c/Users/$WINDOWS_USER/Desktop" ]] && { _warning "Windows Desktop folder $DESKTOP_FOLDER not found, skipping shortcut creation"; return 1; }
	if [[ ! -L "$HOME/Desktop" ]]; then		
		ln -s /mnt/c/Users/$WINDOWS_USER/Desktop ~/Desktop
		OUTPUT+="Created Desktop shortcut"
		DO=1
	fi
	OUTPUT_FULL="WSL: Created shortcuts $OUTPUT"
	
	if [[ $DO == 1 ]]; then		
		_loading3 "$OUTPUT_FULL"
	fi
}

# ===============================================
# -- wsl-screen-fix
# ===============================================
help_wsl[wsl-screen-fix]='Fix screen under WSL'
wsl-screen-fix () {
	# check if screen is installed
	_cmd_exists screen
	if [[ $? -ne 0 ]]; then
		_debug " -- screen not installed"
		return 1
	else
		if [[  ! -d "/run/screen" ]]; then
			_debug " -- Running wsl-screen-fix"
			sudo /etc/init.d/screen-cleanup start
		fi
	fi
}

# ===============================================
# -- wsl-paths
# ===============================================
help_wsl[wsl-paths]='Set WSL paths for Visual Studio Code and VSCode Insiders'
function wsl-paths () {
	# Parse options with zparseopts
	local -a opts_help opts_verbose
	zparseopts -D -E -- h=opts_help -help=opts_help v=opts_verbose -verbose=opts_verbose

	if [[ -n $opts_help ]]; then
		echo "Usage: wsl-paths [-h|--help] [-v|--verbose]"
		echo "Checks and adds VS Code/Insiders to PATH if not already available"
		echo "Also warns if appendWindowsPath is disabled in /etc/wsl.conf"
		return 0
	fi

	local VERBOSE=0 VSCODE_PATH="" VSCODE_INSIDERS_PATH=""
	[[ -n $opts_verbose ]] && VERBOSE=1

	# -- Check if /etc/wsl.conf has appendWindowsPath = false
	if [[ -f /etc/wsl.conf ]]; then
		if grep -qi "appendWindowsPath\s*=\s*false" /etc/wsl.conf 2>/dev/null; then
			_warning "WSL: appendWindowsPath is disabled in /etc/wsl.conf - Windows paths not auto-added to PATH"
		else
			[[ $VERBOSE -eq 1 ]] && _success "appendWindowsPath is enabled in /etc/wsl.conf"
		fi
	else
		[[ $VERBOSE -eq 1 ]] && _log "/etc/wsl.conf not found (using WSL defaults)"
	fi

	# -- Check if WINDOWS_USER is set
	if [[ -z "$WINDOWS_USER" ]]; then
		[[ $VERBOSE -eq 1 ]] && _warning "WINDOWS_USER not set, cannot add VS Code paths"
		return 1
	fi
	[[ $VERBOSE -eq 1 ]] && _log "Windows username: $WINDOWS_USER"

	# -- Check if code already exists in PATH
	if (( $+commands[code] )); then
		[[ $VERBOSE -eq 1 ]] && _success "VS Code (code) already available in PATH: $(which code)"
	else
		[[ $VERBOSE -eq 1 ]] && _log "VS Code (code) not found in PATH, checking Windows installation..."
		VSCODE_PATH="/mnt/c/Users/$WINDOWS_USER/AppData/Local/Programs/Microsoft VS Code/bin"
		if [[ -d "$VSCODE_PATH" ]]; then
			export PATH="$PATH:$VSCODE_PATH"
			[[ $VERBOSE -eq 1 ]] && _success "Added VS Code to PATH: $VSCODE_PATH"
			_debug "Added VS Code to PATH: $VSCODE_PATH"
		else
			[[ $VERBOSE -eq 1 ]] && _warning "VS Code not found at: $VSCODE_PATH"
		fi
	fi

	# -- Check if code-insiders already exists in PATH
	if (( $+commands[code-insiders] )); then
		[[ $VERBOSE -eq 1 ]] && _success "VS Code Insiders already available in PATH: $(which code-insiders)"
	else
		[[ $VERBOSE -eq 1 ]] && _log "VS Code Insiders not found in PATH, checking Windows installation..."
		VSCODE_INSIDERS_PATH="/mnt/c/Users/$WINDOWS_USER/AppData/Local/Programs/Microsoft VS Code Insiders/bin"
		if [[ -d "$VSCODE_INSIDERS_PATH" ]]; then
			export PATH="$PATH:$VSCODE_INSIDERS_PATH"
			[[ $VERBOSE -eq 1 ]] && _success "Added VS Code Insiders to PATH: $VSCODE_INSIDERS_PATH"
			_debug "Added VS Code Insiders to PATH: $VSCODE_INSIDERS_PATH"
		else
			[[ $VERBOSE -eq 1 ]] && _warning "VS Code Insiders not found at: $VSCODE_INSIDERS_PATH"
		fi
	fi
}


# ===============================================
# -- wsl-check-wslu
# ===============================================
help_wsl[wsl-check-wslu]='Check if WSLU is installed'
function wsl-check-wslu () {
	# -- Check if WSLU is installed
	_cmd_exists wslu
	if [[ $? -ne 0 ]]; then
		_log "WSLU not installed, run 'sudo apt install wslu' to install"
		return 1
	fi
}
