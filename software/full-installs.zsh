# =============================================================================
# -- full installs
# =============================================================================

# --------------------------------------------------
# -- maldet
# --------------------------------------------------
help_software[maldet]="Maldet malware scanner from https://www.rfxn.com"
software_maldet () {
	mkdir -p $TMP/maldetect-current
	wget -q -O $TMP/maldetect-current.tar.gz https://www.rfxn.com/downloads/maldetect-current.tar.gz
	tar -zxvf $TMP/maldetect-current.tar.gz --directory maldetect-current --strip-components 1
	cd $TMP/maldetect-current
	./install.sh
}

# --------------------------------------------------
# -- csf-install - Install csf.
# --------------------------------------------------
help_software[csf-install]='Installs CSF. Config Server Firewall'
csf-install () {
	apt-get install libwww-perl -y
	cd /usr/src; rm -fv csf.tgz
	wget https://download.configserver.com/csf.tgz
	tar -xzf csf.tgz
	cd csf
	sh install.sh
}

# --------------------------------------------------
# -- zsh-centos
# --------------------------------------------------
help_software[zsh-install]='Install latest ZSH'
zsh-install () {
	_zsh_install_usage () {
		echo "Usage: zsh-install ([os]|help)"
		echo "  [os]     - Installs ZSH for OS, options are centos7"
		echo "  help             - This help"
		echo ""
		}
	if [[ -z $2 ]]; then
		_zsh_install_usage
		return
	elif [[ $2 == "help" ]]; then
		_zsh_install_usage
		return
	elif [[ $2 == "install" ]]; then
		if [[ $3 == "centos7" ]]; then
			curl -L https://github.com/lmtca/zsh-installs/raw/master/centos/zsh-5.7-3.1.x86_64.rpm  --output /tmp/zsh-5.7-3.1.x86_64.rpm
			rpm -U --replacefiles --replacepkgs /tmp/zsh-5.7-3.1.x86_64.rpm
		else
			_zsh_install_usage
			_error "Missing OS"
			return 1
		fi
	else
		software_zsh_usage
		return
	fi

}

# --------------------------------------------------
# -- ubuntu-netselect
# --------------------------------------------------
help_software[ubuntu-netselect]='Install netselect to find the fastest ubuntu mirror.'
function ubuntu-netselect () {
    _cmd_exists netselect
    if [[ $? == "0" ]]; then
        echo "netselect installed, type 'sudo netselect'"
    elif [[ $? == "1" ]]; then
        _checkroot
        mkdir ~/tmp
        wget http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_amd64.deb -P ~/tmp
        sudo dpkg -i ~/tmp/netselect_0.3.ds1-28+b1_amd64.deb
    fi
}

# --------------------------------------------------
# -- jiq
# --------------------------------------------------
help_software[jiq]='Install jiq a visual cli jq processor'
function software_jiq () {
	if [[ $MACHINE_OS == "mac" ]]; then
		wget "https://github.com/fiatjaf/jiq/releases/download/v0.7.2/jiq_darwin_amd64" -O $ZSHBOP_SOFTWARE_PATH/jiq
		_software_chmod $ZSHBOP_SOFTWARE_PATH/jiq
	elif [[ $MACHINE_OS == "linux" ]]; then
		wget "https://github.com/fiatjaf/jiq/releases/download/v0.7.2/jiq_linux_amd64" -O $ZSHBOP_SOFTWARE_PATH/jiq
		_software_chmod $ZSHBOP_SOFTWARE_PATH/jiq
	fi
}


# --------------------------------------------------
# -- zsh-bin
# --------------------------------------------------
help_software[zsh-bin]='Install zsh-bin from https://github.com/romkatv/zsh-bin'
function zsh-bin() {
    _loading "Running sh -c '$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)'"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)"
}


# --------------------------------------------------
# -- software_cryptomator_cli
# --------------------------------------------------
if [[ -f $ZSHBOP_SOFTWARE_PATH/cryptomator-cli.jar ]]; then
	export CRYPTOMATOR_CLI_JAR=$ZSHBOP_SOFTWARE_PATH/cryptomator-cli.jar
	function cryptomator-cli () {
		java -jar $ZSHBOP_SOFTWARE_PATH/cryptomator-cli.jar $@
	}
else
	alias cryptomator-cli="echo 'cryptomator-cli not installed'"
fi
help_software[cryptomator-cli]="Install cryptomator-cli"
function software_cryptomator-cli () {
	_loading "Installing cryptomator-cli via github jar"
	CRYPTOMATOR_JAR_DL="https://github.com/cryptomator/cli/releases/download/0.5.1/cryptomator-cli-0.5.1.jar"

	# -- check if we have java
	_loading3 "Checking for java"
	if _cmd_exists java; then
		_success "Java installed"
	else
		if [[ $MACHINE_OS == "linux" ]] && [[ $MACHINE_OS_FLAVOUR == "ubuntu" ]]; then		
			_loading3 "Installing openjdk-17-jdk openjdk-17-jre libfuse2 via apt"
			sudo apt install openjdk-17-jdk openjdk-17-jre libfuse2
		else
			_error "Java not installed, please install java and try again"
			return 1
		fi
	fi

	_loading3 "Downloading cryptomator-cli.jar"
	# -- Check if cryptomator-cli.jar exists
	if [[ -f $ZSHBOP_SOFTWARE_PATH/cryptomator-cli.jar ]]; then
		_success "cryptomator-cli.jar already exists"
		return 0
	else
		_loading3 "Downloading cryptomator-cli.jar"	
		wget -O $ZSHBOP_SOFTWARE_PATH/cryptomator-cli.jar $CRYPTOMATOR_JAR_DL
		_success "cryptomator-cli installed, reload zshbop"
	fi
}
