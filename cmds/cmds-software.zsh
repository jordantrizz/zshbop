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

# -- smtp-cli - installs smtp-cli
help_software[smtp-cli]='Installs required packages for smtp-cli'
software_smtp-cli () {
	echo "  -- Installing smtp-cli required packages"
	sudo apt install libio-socket-ssl-perl libdigest-hmac-perl libterm-readkey-perl libmime-lite-perl libfile-libmagic-perl libio-socket-inet6-perl libnet-dns-perl
}

# -- atop
help_software[atop]='Install atop and configure'
software_atop () {
	echo "-- Setting up atop"
	sudo apt-get install atop
	sudo sed -e 's/INTERVAL=600/INTERVAL=300/g' joe /usr/share/atop/atop.daily
	sudo systemctl restart atop
	sudo systemctl enable atop
}

# -- nala
help_software[nala]='apt replacement for Ubuntu and Debian'
software_nala () {
	echo "-- Setting up nala"
	sudo echo "deb [arch=amd64,arm64,armhf] http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
	sudo wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
	sudo apt update && sudo apt install nala
}

# -- nrich
help_software[nrich]='Install nrich'
software_nrich () {
        echo "-- Setting up atop"
        sudo wget -P /tmp https://gitlab.com/api/v4/projects/33695681/packages/generic/nrich/latest/nrich_latest_amd64.deb
	sudo apt-get install /tmp/nrich_latest_amd64.deb
}

