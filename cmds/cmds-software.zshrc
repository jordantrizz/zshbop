# --
# Software commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[software]='Software related commands'

# - Init help array
typeset -gA help_software

# -- vhwinfo - Install vhwinfo.
help_software[vhwinfo]='Installs vhwinfo, dispalys system information.'
vhwinfo () { 
	wget --no-check-certificate https://github.com/rafa3d/vHWINFO/raw/master/vhwinfo.sh -O - -o /dev/null|bash 
}

# -- csf-install - Install csf.
help_software[csf-install]='Installs CSF. Config Server Firewall'
csf-install () { 
	cd /usr/src; rm -fv csf.tgz 
	wget https://download.configserver.com/csf.tgz 
	tar -xzf csf.tgz
	cd csf
	sh install.sh 
}

# -- github-cli - Installs github.com CLI
help_software[github-cli]='Installs github.com cli, aka gh'
github-cli () { 
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
	sudo apt-add-repository https://cli.github.com/packages
	sudo apt update
	sudo apt install gh 
}