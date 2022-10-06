# --
# Software commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"
HELP_CATEGORY='software'

# What help file is this?
help_files[${HELP_CATEGORY}]='Software related commands'
help_files_description[${HELP_CATEGORY}]='The software command provides many functions to install common software'

# - Init help array
typeset -gA help_software

# -- software - Core software command
software () {
	_debug_all "$@"
	if [[ -z $1 ]]; then
		help software
	elif [[ -n $1 ]]; then
		echo " -- Installing software $1"
		_debug "Running command software_$1"
		run_software="software_$1"
		_debug "\$run_software = $run_software"
		$run_software $@
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
	sudo sed -i -e 's/INTERVAL=600/INTERVAL=300/g' /usr/share/atop/atop.daily
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

# -- zsh-centos
help_software[zsh-install]='Install latest ZSH'
zsh_install_usage () {
	echo "Usage: zsh-install ([os]|help)"
	echo "  [os]     - Installs ZSH for OS, options are centos7"
	echo "  help             - This help"
	echo ""
}
zsh-install () {
	if [[ -z $2 ]]; then
		zsh_install_usage
		return
	elif [[ $2 == "help" ]]; then
		zsh_install_usage
		return
	elif [[ $2 == "install" ]]; then
		if [[ $3 == "centos7" ]]; then
			curl -L https://github.com/lmtca/zsh-installs/raw/master/centos/zsh-5.7-3.1.x86_64.rpm  --output /tmp/zsh-5.7-3.1.x86_64.rpm
			rpm -U --replacefiles --replacepkgs /tmp/zsh-5.7-3.1.x86_64.rpm
		else
			zsh_install_usage
			_error "Missing OS"
			return 1
		fi
	else
		software_zsh_usage
		return
	fi

}

# -- my-cli
help_software[mycli]="MySQL CLI Helper with auto complete"
_cexists mycli
if [[ $? -ge "1" ]]; then
	alias mycli=mycli_install
fi
mycli_install () {
	_notice "mycli not installed, installing"
    sudo apt-get install mycli
}

# -- gp-apt
help_software[gp-apt]="Common apps for GridPane Servers"
gp-apt () {
	apt-get install ncdu
}

# -- php-install
help_software[php-install]="One liner for PHP package install"
php-install () {
	_banner_green "For Remi on CentOS"
	echo "yum install php74-{php-recode,php-snmp,php-pecl-apcu,php-ldap,php-pecl-memcached,php-imap,php-odbc,php-xmlrpc,php-intl,php-process,php-pecl-igbinary,php-pear,php-pecl-imagick,php-tidy,php-pspell,php-pdo,php-pecl-mcrypt,php-soap,php-mbstring,php-mysqli}"
	_banner_green "For Ubuntu"
	echo "apt-get install php74-{mbstring,mysql}"
}

# -- aws-cli
help_software[aws-cli]="Install aws-cli"
aws-cli () {
	if [[ ! -d $HOME/downlods ]]; then
		mkdir $HOME/downloads
	fi
	cd $HOME/downloads
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o
	unzip awscli-exe-linux-x86_64.zip
	cd $HOME/downloads/aws
	if [[ -d $HOME/bin ]]; then
		mkdir $HOME/bin
	fi
	./install -i $HOME/bin/aws-cli -b $HOME/bin --update
}

# -- vt
help_software[vt]="Virus Total CLI"
if [[ $MACHINE_OS == "linux" ]] || [[ $MACHINE_OS == "wsl" ]]; then
	_cexists vt-linux64
	if [[ $? -ge "1" ]]; then alias vt=vt-linux64; fi
elif [[ $MACHINE_OS == "mac" ]]; then
	_cexists vt-macos
	if [[ $? -ge "1" ]]; then alias vt=vt-macos; fi
fi
# -- b2
help_software[b2]="Backblaze CLI"
if [[ $MACHINE_OS == "linux" ]] || [[ $MACHINE_OS == "wsl" ]]; then
	_cexists b2-linux
	if [[ $? -ge "1" ]]; then
    	alias b2=b2_download
	else
		alias b2=b2-linux
	fi    	
elif [[ $MACHINE_OS == "mac" ]]; then
	_cexists b2-darwin
    if [[ $? -ge "1" ]]; then
        alias b2=b2_download
    else
        alias b2=b2-darwin
    fi
fi
# -- b2_download
b2_download () {
	_debug_all
	echo "b2 not found, downloading"
	# -- linux
	if [[ $MACHINE_OS == "linux" ]] || [[ $MACHINE_OS == "wsl" ]]; then
		echo "Detected linux OS."
        if [[ -f $HOME/bin/b2-linux ]]; then
			alias b2=b2-linux
		else
			_debug "No b2-linux binary, downloading b2-linux from github to $HOME/bin"
			wget -O $HOME/bin/b2-linux https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux
			chmod u+x $HOME/bin/b2-linux
			if [[ $? -ge 1 ]]; then
				_error "Download failed."
			else 
				_success "b2-linux downloaded to $HOME/bin, run the b2 command"
				alias b2=b2-linux
			fi
		fi
	# -- mac
	elif [[ $MACHINE_OS == "mac" ]]; then
		if [[ $HOME/bin/b2-darwin ]]; then
			alias b2=b2-darwin
		else
			_debug "No b2-darwin binary, downloading b2-linux from github to $HOME/bin"
			wget -O $HOME/bin/b2-darwin https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-darwin
			if [[ $? -eg 1 ]]; then
   	            _error "Download failed."
	        else
		        _success "b2-darwin downloaded to $HOME/bin, run the b2 command"
		        alias b2=b2-darwin
        	fi
		fi
	fi	
}	

# -- powershell
help_software[b2]="Powershell for Linux"
_cexists pwsh
if [[ $? -ge "1" ]]; then
	alias pwsh=powershell_download
else
	alias pwsh=pwsh
fi
powershell_download () {
	echo "Installing Powershell on Ubuntu"
	# Update the list of packages
	sudo apt-get update
	# Install pre-requisite packages.
	sudo apt-get install -y wget apt-transport-https software-properties-common
	# Download the Microsoft repository GPG keys
	wget -q -O $TMP/packages-microsoft-prod.deb "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
	# Register the Microsoft repository GPG keys
	sudo dpkg -i $TMP/packages-microsoft-prod.deb
	# Update the list of packages after we added packages.microsoft.com
	sudo apt-get update
	# Install PowerShell
	sudo apt-get install -y powershell
}