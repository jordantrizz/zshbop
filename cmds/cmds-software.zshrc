# --
# Software commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[software_description]="-- To install, run software <cmd>"
help_files[software]='Software related commands'

# - Init help array
typeset -gA help_software

# -- software - Core software command
software () {
	if [[ ! $1 ]]; then
		help software
	elif [[ $1 ]]; then
		echo " -- Installing software $1"
		_debug "Running command software_$1"
		run_software="software_$1"
		_debug "\$run_software = $run_software"
		$run_software
	fi
}

# -- csf-install - Install csf.
help_software[csf-install]='Installs CSF. Config Server Firewall'
software_csf-install () { 
	cd /usr/src; rm -fv csf.tgz 
	wget https://download.configserver.com/csf.tgz 
	tar -xzf csf.tgz
	cd csf
	sh install.sh 
}

# -- github-cli - Installs github.com CLI
help_software[gh-cli]='Installs github.com cli, aka gh'
software_gh-cli () { 
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
	sudo apt-add-repository https://cli.github.com/packages
	sudo apt update
	sudo apt install gh 
}

# -- mdv - Installs github.com CLI
help_software[mdv]='Installs github.com cli, aka gh'
software_mdv () {
        # Old method that is broken
        #sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
        #sudo apt-add-repository https://cli.github.com/packages
        #sudo apt update
        #sudo apt install gh                
	repos terminal_markdown_viewer
        cd $ZSHBOP_ROOT/repos/terminal_markdown_viewer
        pip install .
}

# -- asciinema - Installs asciinema 
help_software[asciinema]='Installs asciinema'
software_asciinema () {
	sudo apt-get install asciinema 
}