# -- Windows WSL Related Commands
# -- Variables

# -- Functions
function wsl () {
	# Fix traceroute on WSL
	if [ $1 == 'traceroute' ]; then
		sudo apt-get update
		sudo apt install inetutils-traceroute
		sudo apt install traceroute
	fi
}

function fixscreen () {
	# -- Screen fix https://github.com/microsoft/WSL/issues/1245 
	if [ -d "/run/screen" ]; then
	else
		sudo /etc/init.d/screen-cleanup start
	fi
}

# -- Aliases
alias traceroute="sudo traceroute -M icmp"

# -- Init
fixscreen
