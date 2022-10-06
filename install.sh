#!/usr/bin/env bash
# ------------------------
# -- zshbop Install script
# ------------------------

# ------------
# -- Variables
# ------------
CMD=$1
required_tools=('jq' 'curl' 'zsh' 'git' 'md5sum' 'sudo')

# -- Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
BLUEBG="\033[0;44m"
YELLOWBG="\033[0;43m"
GREENBG="\033[0;42m"
DARKGREYBG="\033[0;100m"
ECOL="\033[0;0m"

# ------------
# -- Functions
# ------------

# -- _error
_error () {
    echo -e "${RED}** ERROR ** - $@ ${ECOL}"
}

_warning () {
    echo -e "${YELLOW}** ERROR ** - $@ ${ECOL}"
}

_success () {
    echo -e "${GREEN}** SUCCESS ** - $@ ${ECOL}"
}

_running () {
    echo -e "${BLUEBG}${@}${ECOL}"
}


# ------------
# -- Functions
# ------------

# -- flight_check
flight_check() {
   # Checking if zsh is installed
   _running "Checking if required tools are installed"
	for tool in ${required_tools[@]}; do
        	if ! [ -x "$(command -v $tool)" ]; then
                	_error "$tool is not installed."
                	pkg_install $tool
	        else
        	        TOOL_PATH=`which $tool`
	                _success "$tool is installed in $TOOL_PATH"
	        fi
	done
	return        
}

# -- check_zsh_default
check_zsh_default () {
        # Check if zsh is the default shell
        _running "Checking if zsh is the default shell...."
        if ! [[ $SHELL == *"zsh" ]]; then
                _warning " Your default shell isn't zsh, use chsh to change it to zsh."
        else
                _success -e "- ZSH is your default shell!"
        fi

}

# -- pkg_install - install packafges.
pkg_install() {
	# Checking what package manager we have
    _running "Checking what package manager we have...."
    if [ -x "$(command -v apt-get)" ]; then
    	echo " - We have apt!"
        sudo apt install -f $@
        	if [ $? -eq 1 ]; then 
            	_error "$@ install failed...."
                exit 1
            else
	            _success "$@ installed successfully"
            fi
	elif [ -x "$(command -v yum)" ]; then
    	echo " - We have yum!"
        sudo yum install $@
		if [ $? -eq 1 ]; then 
			_error "$@ install failed...."
			exit 1
		else
			_success "$@ installed successfully"
		fi
	else
		_error "Can't detect package manager :("
    fi
}

# -- install_method - how do you want to install zshbop?
install_method() {
	echo "Install (d)efaults or (c)ustomize? (d/c)?"
	read INSTALL

	if [ $INSTALL == "d" ];then
		INSTALL_LOCATION=s
		BRANCH=m
	elif [ $INSTALL == "c" ]; then
	        echo "Do you want to install system wide or home only? (s/h)"
	        read INSTALL_LOCATION
	        echo "(d)ev or (m)ain Branch? (d/m)"
	        read BRANCH
	fi
}

# -- clone_repository
clone_repository() {
        if ! [ -d $1 ];then
                _running "Start Cloning repository into $1..."
                if [[ $BRANCH == "d" ]]; then
                        git clone --branch dev https://github.com/jordantrizz/zshbop.git $1
                elif [[ $BRANCH == "m" ]]; then
                        git clone https://github.com/jordantrizz/zshbop.git $1
		fi		
        else
                _error "Directory $1 exists...exiting."
                exit 1
        fi
}

# -- setup_home
setup_home() {
	if ! [ -f $HOME/.zshrc ]; then
		if [[ $1 == "git" ]]; then
			SETUP_PATH="$HOME/git"
			echo "- Install path - $SETUP_PATH"
		else
			SETUP_PATH="$HOME"
			echo "- Install path - $SETUP_PATH"
		fi
		clone_repository "$SETUP_PATH/zshbop"
	       	cp $SETUP_PATH/zshbop/.zshrc $HOME/.zshrc
	       	_success "- ZSH in-place at $SETUP_PATH, type zsh to start your shell\n"
	else
	       	_error "- There's already a .zshrc in-place, remove it and re-run\n"
	       	exit 1
	fi
}

# -- setup_system
setup_system() {
	# Confirm that /usr/local/sbin exists
	_running "Setting up system based .zshrc..."
	SYSTEM=/usr/local/sbin
	if ! [ -d "$SYSTEM/zshbop" ]; then
		echo -e " - Cloning into $SYSTEM/zshbop\n"
		clone_repository "$SYSTEM/zshbop"
	else
		_error " - $SYSTEM/zshbop already exists\n"
		exit 1
	fi
	# Uncommented for now, need to review
	#echo -e " - Detecting OS and installing for all system users"
	#if [ -f /etc/debian_version ]; then
	#	echo -e " -- Detected Debian/Ubuntu OS"		
	#fi
	#echo "This is broken and needs to be fixed! and should probably be in /usr/share/zshbop?"
	
	_success -e "Copied $SYSTEM/zshbop/.zshrc to ~/.zshrc"
	cp $SYSTEM/zshbop/.zshrc ~/.zshrc

}		

# -------
# -- Main
# -------
if [[ $CMD == "clean" ]]; then
	_running "Removing zshbop ###"
	echo "Continue (y/n)?"
	read CLEAN
	
	if [ $CLEAN == "y" ]; then
		_running "Cleaning up!"		
		rm ~/.zshrc
		rm -rf /usr/local/sbin/zshbop
		rm -rf ~/zshbop
		exit
	else
		loading "Aboring....Goodbye!"
		exit
	fi
fi

if [[ $CMD == "skipdep" ]]; then
	_running -e "Skipping pre-flight check"
else
	_running "Pre-flight Check"
	flight_check
fi

_running "Begin Install"

if [[ $CMD == "default" ]]; then
        INSTALL=d
elif [[ $CMD == "home" ]]; then
        INSTALL=c
        BRANCH=m
        INSTALL_LOCATION=h
elif [[ $CMD == "git" ]]; then
	INSTALL=c
	BRANCH=d
	INSTALL_LOCATION=g
else
	install_method
fi

if [[ $INSTALL == "d" ]]; then
	setup_system
elif [[ $INSTALL == "c" ]]; then
	if [ $INSTALL_LOCATION == "s" ]; then
	        setup_system
	elif [ $INSTALL_LOCATION == "h" ]; then
	        setup_home
	elif [ $INSTALL_LOCATION == "g" ]; then
		setup_home git
	fi
fi

_success "Installation complete."
