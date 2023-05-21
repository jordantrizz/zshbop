# --
# WSL commands
#
# Example help: help_wsl[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[wsl]='Windows Subsystem for Linux commands'

# - Init help array
typeset -gA help_wsl

# ----------------
# -- Run Commands
# ----------------
# -- traceroute - fixes WSL traceroute command
alias traceroute="sudo traceroute -M icmp"

# -- wsl-fixscreen - Fix screen when in WSL.
help_wsl[wsl-fixscreen]='Fix screen under WSL'
function wsl-fixscreen () {
	# -- Screen fix https://github.com/microsoft/WSL/issues/1245 
	if [ -d "/run/screen" ]; then
	else
		sudo /etc/init.d/screen-cleanup start
	fi
}
wsl-fixscreen

# ------------
# -- Functions
# ------------

# -- wsl-fixes
help_wsl[wsl-fixes]='Fix issues under WSL'
function wsl-fixes () {
	# -- Fix traceroute on WSL
	echo "-- Fixing traceroute under WSL"
	sudo apt-get update
	sudo apt install inetutils-traceroute
	sudo apt install traceroute
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


