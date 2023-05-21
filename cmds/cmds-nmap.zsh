# --
# Core commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
#
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[nmap]='Nmap commands'

# - Init help array
typeset -gA help_nmap

_debug " -- Loading ${(%):-%N}"


# -- ping-sweep
help_nmap[ping-sweep]="Ping sweep, return on line hosts with ARP and vendor ID's"
ping-sweep () {
	if [[ -z $1 ]]; then
        echo "Usage: ping-sweep <range>"
        echo "	Example: ping-sweep 192.168.1.1-255"
	else
        _require_pkg nmap
        nmap -sP $1
	fi
}

# -- open-ports
help_nmap[open-ports]="Scan open ports -F (Fast)"
open-ports () {
		if [[ -z $1 ]]; then
			echo "Usage: open-ports <range>"
			echo "	Example: open-ports 192.168.1.1"
		else
			_require_pkg nmap
            nmap -T4 -n -Pn $1
		fi
}
