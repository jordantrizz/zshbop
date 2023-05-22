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

# - Init help array
typeset -gA help_software

# -- software - Core software command
function software () {
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
csf-install () {
	apt-get install libwww-perl -y
	cd /usr/src; rm -fv csf.tgz
	wget https://download.configserver.com/csf.tgz
	tar -xzf csf.tgz
	cd csf
	sh install.sh
}

# -- github-cli - Installs github.com CLI
help_software[gh-cli-deb]='Installs github.com cli, aka gh'
software_gh-cli-deb () {
	type -p curl >/dev/null || sudo apt install curl -y
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
}

# -- mdv - Installs github.com CLI
help_software[mdv]='Installs github.com cli, aka gh'
software_mdv () {
	pip install mdv
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
	_banner_green "For Ubuntu and Litespeed"
	echo "apt-get install lsphp81-{recode,snmp,pecl-apcu,ldap,pecl-memcached,imap,odbc,xmlrpc,intl,process,pecl-igbinary,pear,pecl-imagick,tidy,pspell,pdo,pecl-mcrypt,soap,mbstring,mysqli}"
}

# -- aws-cli
help_software[aws-cli]="Install aws-cli"
aws-cli () {
	if [[ ! -d $HOME/downlods ]]; then
		mkdir $HOME/downloads
	fi
	cd $HOME/downloads
	curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscli-exe-linux-x86_64.zip
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
	[[ $? -ge "0" ]] && alias vt=vt-linux64 || alias vt="echo 'VT not installed'"
elif [[ $MACHINE_OS == "mac" ]]; then
	_cexists vt-macos
	[[ $? -ge "0" ]] && alias vt=vt-macos || alias vt="echo 'VT not installed'"
fi
# -- b2
help_software[b2]="Backblaze CLI"
if [[ $MACHINE_OS == "linux" ]] || [[ $MACHINE_OS == "wsl" ]]; then
	_cexists b2-linux
    [[ $? -ge "1" ]] && alias b2=b2_download || alias b2=b2-linux
elif [[ $MACHINE_OS == "mac" ]]; then
	_cexists b2-darwin
    [[ $? -ge "1" ]] && alias b2=b2_download || alias b2=b2-darwin
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
help_software[powershell]="Powershell for Linux"
_cexists pwsh
[[ $? -ge "1" ]] && alias pwsh=powershell_download || alias pwsh=pwsh

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

# -- maldet
help_software[maldet]="Maldet malware scanner from https://www.rfxn.com"
software_maldet () {
	mkdir -p $TMP/maldetect-current
	wget -q -O $TMP/maldetect-current.tar.gz https://www.rfxn.com/downloads/maldetect-current.tar.gz
	tar -zxvf $TMP/maldetect-current.tar.gz --directory maldetect-current --strip-components 1
	cd $TMP/maldetect-current
	./install.sh
}

# -- software_speedtest-cli
help_software[speedtest-cli]="Speedtest-cli from https://github.com/sivel/speedtest-cli"
software_speedtest-cli () {
	if [[ -f $HOME/bin ]]; then
		cd $HOME/bin
	else
		mkdir $HOME/bin
		cd $HOME/bin
	fi
    wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
    chmod +x speedtest-cli
    sed -i 's/env python$/env python3/g' $HOME/bin/speedtest-cli
}

# -- software_gh-cli-curl
help_software[gh-cli-curl]="Install github cli"
software_gh-cli-curl () {
	VERSION=`curl  "https://api.github.com/repos/cli/cli/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c2-`
	if [[ ! -f $HOME/tmp ]]; then
    	mkdir -p $HOME/bin
	fi

	curl -sSL https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_amd64.tar.gz -o $HOME/tmp/gh_${VERSION}_linux_amd64.tar.gz
	cd $HOME/tmp
	tar xvf gh_${VERSION}_linux_amd64.tar.gz

	if [[ -f $HOME/bin ]]; then
	    cd $HOME/bin
	else
	    mkdir -p $HOME/bin
	    cd $HOME/bin
	fi
	cp $HOME/tmp/gh_${VERSION}_linux_amd64/bin/gh $HOME/bin
}

# -- ubuntu-netselect
help_software[ubuntu-netselect]='Install netselect to find the fastest ubuntu mirror.'
function ubuntu-netselect () {
    _cexists netselect
    if [[ $? == "0" ]]; then
        echo "netselect installed, type 'sudo netselect'"
    elif [[ $? == "1" ]]; then
        _checkroot
        mkdir ~/tmp
        wget http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_amd64.deb -P ~/tmp
        sudo dpkg -i ~/tmp/netselect_0.3.ds1-28+b1_amd64.deb
    fi
}

# -- jiq
help_software[jiq]='Install jiq a visual cli jq processor'
function software_jiq () {
	if [[ ! -f $HOME/bin ]]; then
		mkdir $HOME/bin
	fi

	if [[ $MACHINE_OS == "mac" ]]; then
		wget "https://github.com/fiatjaf/jiq/releases/download/v0.7.2/jiq_darwin_amd64" -O $HOME/bin/jiq
		chmod u+x $HOME/bin/jiq
	elif [[ $MACHINE_OS == "linux" ]]; then
		wget "https://github.com/fiatjaf/jiq/releases/download/v0.7.2/jiq_linux_amd64" -O $HOME/bin/jiq
		chmod u+x $HOME/bin/jiq
	fi
}

# -- plik-conf
help_software[plik-conf]='Print out .plikrc'
function plik-conf () {    
    if [[ ! -f $HOME/.plikrc ]]; then
        _error "No $HOME/.plikrc exists"
        return 1
    else
        PLIKRC=$(cat $HOME/.plikrc)
        echo "echo '${PLIKRC}' > \$HOME/.plikrc"
    fi
}

# -- zsh-bin
help_software[zsh-bin]='Install zsh-bin from https://github.com/romkatv/zsh-bin'
function zsh-bin() {
    _loading "Running sh -c '$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)'"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)"
}

# -- bat
help_software[bat]="Install bat"
function bat() {
    _loading "Installing bat"
    if [[ $MACHINE_OS == "mac" ]]; then
        brew install bat
    elif [[ $MACHINE_OS == "linux" ]]; then
        sudo apt install bat
    fi
}

# -- glint
help_software[change]="Install glint - https://github.com/brigand/glint"
if [[ $MACHINE_OS == "linux" ]]; then
    _cexists glint-linux
    if [[ $? == "0" ]]; then
    	function glint () { glint-linux $* } 
    	function software_glint { _success "Glint installed" }
    else
		function glint () { _error "Glint not installed, type software glint to install" }
		function software_glint { 
    		_loading "Installing glint"
	    	curl -L -o $HOME/bin/glint-linux https://github.com/brigand/glint/releases/download/v6.3.4/glint-linux
	    	chmod u+x $HOME/bin/glint-macos
	    	_loading3 "Reload shell"
    	}
    fi
elif [[ $MACHINE_OS == "mac" ]]; then
    _cexists glint-macos
    if [[ $? == "0" ]]; then
    	function glint () { glint-macos $* } 
    	function software_glint { _success "Glint installed" }
    else 
		function glint () { _error "Glint not installed, type software glint to install" }
        function software_glint {
            _loading "Installing glint"
			curl -L -o $HOME/bin/glint-macos https://github.com/brigand/glint/releases/download/v6.3.4/glint-macos
			chmod u+x $HOME/bin/glint-macos
			_loading3 "Reload shell"
        }
    fi
fi

# -- change
help_software[change]="Install change - https://raw.githubusercontent.com/adamtabrams/change"
_cexists change
if [[ $? == "1" ]]; then
	function change () {
		if [[ ! -f $BIN/home ]]; then
			_zshbop_bin
			curl -s "https://raw.githubusercontent.com/adamtabrams/change/master/change" -o $HOME/bin
		else
			_zshbop_bin
		fi
	}
fi