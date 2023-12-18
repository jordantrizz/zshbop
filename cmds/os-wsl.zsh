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
	wsl-fixscreen
	wsl-backupwtc
	wsl-shortcuts
	init_log
}

# ==================================================
# -- Functions
# ==================================================

# -- wsl-fixscreen - Fix screen when in WSL.
help_wsl[wsl-fixscreen]='Fix screen under WSL'
function wsl-fixscreen () {
	# -- Screen fix https://github.com/microsoft/WSL/issues/1245 
	if [ -d "/run/screen" ]; then
	else
		sudo /etc/init.d/screen-cleanup start
	fi
}

# -- wsl-fixes
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

# -- wsl-backupwtc 
help_wsl[wsl-backupwtc]='Backup Windows Terminal configuration.'
wsl-backupwtc () {
	local WT_SOURCE="$(echo /mnt/c/Users/$USER/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json)"
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

# -- check_diskspace_wsl
help_wsl[check_diskspace_wsl]='Check disk space under WSL'
function check_diskspace_wsl () {
    # -- Check disk space
    if [[ $1 == "show" ]]; then
        _error "Checking disk space for WSL not implemented yet."
    else
        _error "Checking disk space for WSL not implemented yet."
    fi
    
}

# -- wsl-shortcuts
help_wsl[wsl-shortcuts]='Create Downloads and Desktop shortcuts for WSL'
function wsl-shortcuts () {
	local OUTPUT="" DO=0 OUTPUT_FULL=""
	# -- Create shortcuts
	
	if [[ ! -d "$HOME/Downloads" ]]; then		
		ln -s /mnt/c/Users/$USER/Downloads ~/Downloads	
		OUTPUT+="$HEADER Created Downloads shortcut."
		DO=1
	fi
	if [[ ! -d "$HOME/Desktop" ]]; then		
		ln -s /mnt/c/Users/$USER/Desktop ~/Desktop
		OUTPUT+="Created Desktop shortcut"
		DO=1
	fi
	OUTPUT_FULL="WSL: Created shortcuts $OUTPUT"
	
	if [[ $DO == 1 ]]; then		
		_loading3 "$OUTPUT_FULL"
	fi
}

