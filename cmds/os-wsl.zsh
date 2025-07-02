# ====================================================================================================
# -- WSL commands
# ====================================================================================================
_debug " -- Loading ${(%):-%N}"
help_files[wsl]='Windows Subsystem for Linux commands'
typeset -gA help_wsl

# ==================================================
# -- Aliases
# ==================================================
# -- traceroute - fixes WSL traceroute command
alias traceroute="sudo traceroute -M icmp"

# ==================================================
# -- Run Commands
# --
# -- These commands run on WSL startup
# ==================================================
# -- init_wsl
init_wsl () {
	_debug " -- Running init_wsl"
	wsl-fixes
	wsl-screen-fix
	wsl-backupwtc 1
	wsl-shortcuts
	init_log
	wsl-paths
	wsl-check-wslu
}

# =================================================================================================
# -- Functions
# =================================================================================================

# ==================================================
# -- wsl-fixes
# ==================================================
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

# ==================================================
# -- wsl-backupwtc 
# ==================================================
help_wsl[wsl-backupwtc]='Backup Windows Terminal configuration.'
wsl-backupwtc () {
	local WIN_USER=$(powershell.exe '$env:UserName' 2>/dev/null | sed -e 's/\r//g')
	local WT_SOURCE="$(echo /mnt/c/Users/$WIN_USER/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json)"
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

# ==================================================
# -- check_diskspace_wsl
# ==================================================
help_wsl[wsl-check-diskspace]='Check disk space under WSL'
function wsl-check-diskspace () {
    # -- Check disk space
    if [[ $1 == "show" ]]; then
        _error "Checking disk space for WSL not implemented yet."
    else
        _error "Checking disk space for WSL not implemented yet."
    fi
    
}

# ==================================================
# -- wsl-shortcuts
# ==================================================
help_wsl[wsl-shortcuts]='Create Downloads and Desktop shortcuts for WSL'
function wsl-shortcuts () {
	local OUTPUT="" DO=0 OUTPUT_FULL=""
	local WIN_USER DOWNLOAD_FOLDER DESKTOP_FOLDER
	WIN_USER=$(powershell.exe '$env:UserName' 2>/dev/null | sed -e 's/\r//g')
	# -- Create shortcuts
	
	# -- Check to see if Downloads folder exists
	DOWNLOAD_FOLDER="/mnt/c/Users/$WIN_USER/Downloads"
	[[ ! -d "$DOWNLOAD_FOLDER" ]] && { _warning "Windows Downloads folder $DOWNLOAD_FOLDER not found, skipping shortcut creation"; return 1; }
	# Check if Downloads folder exists as symlink
	if [[ ! -L "$HOME/Downloads" ]]; then
		ln -s /mnt/c/Users/$WIN_USER/Downloads ~/Downloads	
		OUTPUT+="$HEADER Created Downloads shortcut."
		DO=1
	fi
	# -- Create Desktop shortcut
	DESKTOP_FOLDER="/mnt/c/Users/$WIN_USER/Desktop"
	[[ ! -d "/mnt/c/Users/$WIN_USER/Desktop" ]] && { _warning "Windows Desktop folder $DESKTOP_FOLDER not found, skipping shortcut creation"; return 1; }
	if [[ ! -L "$HOME/Desktop" ]]; then		
		ln -s /mnt/c/Users/$WIN_USER/Desktop ~/Desktop
		OUTPUT+="Created Desktop shortcut"
		DO=1
	fi
	OUTPUT_FULL="WSL: Created shortcuts $OUTPUT"
	
	if [[ $DO == 1 ]]; then		
		_loading3 "$OUTPUT_FULL"
	fi
}

# ==================================================
# -- wsl-screen-fix
# ==================================================
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

# ==================================================
# -- wsl-paths
# ==================================================
help_wsl[wsl-paths]='Set WSL paths for Visual Studio Code'
function wsl-paths () {
	# Get current windows user
	local WINDOWS_USER=$(/mnt/c/Windows/System32/cmd.exe /c 'echo %USERNAME%' 2> /dev/null | sed -e 's/\r//g')
	# -- Set WSL paths for Visual Studio Code
	export PATH=$PATH:"/mnt/c/Users/$WINDOWS_USER/AppData/Local/Programs/Microsoft VS Code/bin"
}


# ==================================================
# -- wsl-check-wslu
# ==================================================
help_wsl[wsl-check-wslu]='Check if WSLU is installed'
function wsl-check-wslu () {
	# -- Check if WSLU is installed
	_cmd_exists wslu
	if [[ $? -ne 0 ]]; then
		_log "WSLU not installed, run 'sudo apt install wslu' to install"
		return 1
	fi
}