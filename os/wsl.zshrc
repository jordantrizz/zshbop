# -- Windows WSL Related Commands
function wsl () {
	# Fix traceroute on WSL
	if [ $1 == 'traceroute' ]; then
		sudo apt-get update
		sudo apt install inetutils-traceroute
		sudo apt install traceroute
	fi
}
alias traceroute="sudo traceroute -M icmp"
alias fixscreen="sudo /etc/init.d/screen-cleanup start"
