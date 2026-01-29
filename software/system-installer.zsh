# ====================================================================================================
# -- system installer based software
# ====================================================================================================

# --------------------------------------------------
# -- smtp-cli - installs smtp-cli
# --------------------------------------------------
help_software[smtp-cli]='Installs required packages for smtp-cli'
software_smtp-cli () {
	echo "  -- Installing smtp-cli required packages"
	sudo apt install libio-socket-ssl-perl libdigest-hmac-perl libterm-readkey-perl libmime-lite-perl libfile-libmagic-perl libio-socket-inet6-perl libnet-dns-perl
}

# --------------------------------------------------
# -- php-install
# --------------------------------------------------
help_software[php-install]="One liner for PHP package install"
php-install () {
	_loading "For Remi on CentOS"
	echo "yum install php74-{php-recode,php-snmp,php-pecl-apcu,php-ldap,php-pecl-memcached,php-imap,php-odbc,php-xmlrpc,php-intl,php-process,php-pecl-igbinary,php-pear,php-pecl-imagick,php-tidy,php-pspell,php-pdo,php-pecl-mcrypt,php-soap,php-mbstring,php-mysqli}"
	_loading "For Ubuntu"
	echo "apt-get install php74-{mbstring,mysql}"
	_loading "For Ubuntu and Litespeed"
	echo "apt-get install -f lsphp81-{snmp,ldap,imap,intl,tidy,pspell,mysql,redis,igbinary,opcache,curl,imagick,memcached,msgpack}"
}


# --------------------------------------------------
# -- gp-apt
# --------------------------------------------------
help_software[gp-apt]="Common apps for GridPane Servers"
gp-apt () {
	apt-get install ncdu
}


# --------------------------------------------------
# -- my-cli
# --------------------------------------------------
help_software[mycli]="MySQL CLI Helper with auto complete"
_cmd_exists mycli
if [[ $? -ge "1" ]]; then
	alias mycli=mycli_install
fi
mycli_install () {
	_notice "mycli not installed, installing"
    sudo apt-get install mycli
}


# --------------------------------------------------
# -- nala
# --------------------------------------------------
help_software[nala]='apt replacement for Ubuntu and Debian'
software_nala () {
	echo "-- Setting up nala"
	sudo echo "deb [arch=amd64,arm64,armhf] http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
	sudo wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
	sudo apt update && sudo apt install nala
}

# --------------------------------------------------
# -- nrich
# --------------------------------------------------
help_software[nrich]='Install nrich'
software_nrich () {
    echo "-- Setting up atop"
    sudo wget -P /tmp https://gitlab.com/api/v4/projects/33695681/packages/generic/nrich/latest/nrich_latest_amd64.deb
	sudo apt-get install /tmp/nrich_latest_amd64.deb
}

# --------------------------------------------------
# -- atop
# --------------------------------------------------
help_software[atop]='Install atop and configure'
software_atop () {	
	if [[ -z $2 ]]; then
		_notice "Missing interval using default 300 seconds"
		INTERVAL=300		
	else
		INTERVAL=$2
	fi
	
	_loading "Installing and Setting up atop top run every $INTERVAL seconds"
	
	_loading2 "Installing atop"
	if _cmd_exists atop; then
		_notice "atop already installed"		
	else
		_loading3 "Installing atop"
		sudo apt-get install atop
	fi

	_loading2 "Setting up atop with interval $INTERVAL"
	sudo sed -i -e 's/INTERVAL=600/INTERVAL=300/g' /usr/share/atop/atop.daily
	
	_loading2 "Restarting atop"
	sudo systemctl restart atop
	sudo systemctl enable atop
}

# --------------------------------------------------
# -- mdv - Installs github.com CLI
# --------------------------------------------------
help_software[mdv]='Installs github.com cli, aka gh'
software_mdv () {
	pip install mdv
}

# --------------------------------------------------
# -- asciinema - Installs asciinema
# --------------------------------------------------
help_software[asciinema]='Installs asciinema'
software_asciinema () {
	sudo apt-get install asciinema
}

# --------------------------------------------------
# -- bat
# --------------------------------------------------
help_software[bat]="Install bat"
function bat() {
    _loading "Installing bat"
    if [[ $MACHINE_OS == "mac" ]]; then
        brew install bat
    elif [[ $MACHINE_OS == "linux" ]]; then
        sudo apt install bat
    fi
}

# --------------------------------------------------
# -- github-cli - Installs github.com CLI
# --------------------------------------------------
help_software[gh-cli-deb]='Installs github.com cli, aka gh'
software_gh-cli-deb () {
	type -p curl >/dev/null || sudo apt install curl -y
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
}


# --------------------------------------------------
# -- powershell
# --------------------------------------------------
help_software[powershell]="Powershell for Linux"
_cmd_exists pwsh
[[ $? -ge "1" ]] && alias pwsh=software_powershell || alias pwsh=pwsh

software_powershell () {
	if [[ $MACHINE_OS == "mac" ]]; then
		echo "Installing Powershell on Mac using brew"
		brew install --cask powershell
	else
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
	fi
}

# --------------------------------------------------
# -- ncdu
# --------------------------------------------------
help_software[ncdu]="Install ncdu"
_cmd_exists ncdu
if [[ $? == "1" ]]; then
    function ncdu () {
        if [[ $MACHINE_OS == "mac" ]]; then
            brew install ncdu
        elif [[ $MACHINE_OS == "linux" ]]; then
            sudo apt install ncdu
        fi
		unset -f ncdu
    }
fi

# --------------------------------------------------
# -- php-relay
# --------------------------------------------------
help_software[php-relay]="Install php-relay"
function php-relay () {
    _loading "Installing php-relay"
    _loading3 "Adding repo to apt"
    curl -s https://repos.r2.relay.so/key.gpg | sudo apt-key add -
    sudo add-apt-repository "deb https://repos.r2.relay.so/deb $(lsb_release -cs) main"
    sudo apt update
    _loading3 "Installing php-relay package"
    sudo apt install php-relay
    _success "Installed php-relay default PHP vesion"
    echo "Other versions can be installed with 'apt-get install php8.1-relay'"
    echo "Litespeed or Openlitespeed servers need additional configuration see kb php-relay.md"
}

# --------------------------------------------------
# -- pie
# --------------------------------------------------
help_software[pie]="Install PHP pie (Package Installer for Extensions)"
function software_pie () {
    _loading "Installing pie dependencies"
    sudo apt install -y gcc make autoconf libtool bison re2c pkg-config php-dev
    
    _loading3 "Downloading pie.phar"
    sudo curl -L -o /usr/local/bin/pie https://github.com/php/pie/releases/download/1.3.7/pie.phar
    
    _loading3 "Making pie executable"
    sudo chmod +x /usr/local/bin/pie
    
    _success "pie installed successfully"
    pie --version
}

# --------------------------------------------------
# -- goaccess
# --------------------------------------------------
help_software[goaccess]="Install goaccess latest"
function software_goaccess () {
    if [[ $MACHINE_OS == "linux" && $MACHINE_OS_FLAVOUR == "debian" ]]; then
        wget -O - https://deb.goaccess.io/gnugpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/goaccess.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/goaccess.gpg arch=$(dpkg --print-architecture)] https://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/goaccess.list
        sudo apt-get update
        sudo apt-get install goaccess
    else
        _error "goaccess not supported on $MACHINE_OS"
    fi
}



# --------------------------------------------------
# -- fpart
# --------------------------------------------------
help_software[fpart]="Install fpart"
function software_fpart () {
	if [[ $MACHINE_OS == "linux" && $MACHINE_OS_FLAVOUR == "debian" ]]; then
		sudo apt-get install fpart bsd-mailx- postfix- --no-install-recommends
	else
		_error "fpart not supported on $MACHINE_OS"
	fi
}

# --------------------------------------------------
# -- gcloud
# --------------------------------------------------
help_software[gcloud]="Install gcloud"
function software_gcloud () {
	if [[ $MACHINE_OS_FLAVOUR == "ubuntu" ]]; then
		_loading "Installing gcloud"
		_loading3 "Adding repo to apt"
		echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
		curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
		sudo apt-get update
		_loading3 "Installing gcloud"
		sudo apt-get install google-cloud-sdk
	else
		_error "gcloud not supported on $MACHINE_OS / $MACHINE_OS_FLAVOUR"
	fi
}

# ====================================================================================================
# -- fzf
# ====================================================================================================
help_software[fzf]="Install fzf"
function software_fzf () {
	if [[ $MACHINE_OS == "mac" ]]; then
		brew install fzf
	elif [[ $MACHINE_OS == "linux" ]]; then
		sudo apt-get install fzf
	fi
}

# ====================================================================================================
# docker-ctop
# ====================================================================================================
help_software[docker-ctop]="Install docker-ctop"
function software_docker-ctop() {
	if [[ $MACHINE_OS == "linux" ]]; then
		sudo apt-get install ca-certificates curl gnupg lsb-release
		curl -fsSL https://azlux.fr/repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/azlux-archive-keyring.gpg
		echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian \
		stable main" | sudo tee /etc/apt/sources.list.d/azlux.list >/dev/null
		sudo apt-get update
		sudo apt-get install docker-ctop
	else
		_error "docker-ctop not supported on $MACHINE_OS"
	fi
}