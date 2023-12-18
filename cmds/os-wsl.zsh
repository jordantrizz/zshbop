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
	_cexists traceroute
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
        cp /mnt/c/Users/$USER/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json  $ZSH_ROOT/files/wt_settings.json
        gcp "Backup of Windows Terminals settings.json"
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
	# -- Create shortcuts
	_loading3 "WSL -- Creating shortcuts for Downloads and Desktop"
	if [[ ! -d "$HOME/Downloads" ]]; then		
		ln -s /mnt/c/Users/$USER/Downloads ~/Downloads	
		_loading3 "Created Downloads shortcut"
	fi
	if [[ ! -d "$HOME/Desktop" ]]; then		
		ln -s /mnt/c/Users/$USER/Desktop ~/Desktop
		_loading3 "Created Downloads shortcut"
	fi
}

# ==================================================
# -- Run Commands
# --
# -- These commands run on WSL startup
# ==================================================
wsl-fixscreen
wsl-shortcuts