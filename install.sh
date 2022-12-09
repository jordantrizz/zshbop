#!/usr/bin/env bash
# ------------------------
# -- zshbop Install script
# ------------------------

# ------------
# -- Variables
# ------------
VERSION="0.0.2"
SKIPDEP="0"
HELP="0"
required_tools=('jq' 'curl' 'zsh' 'git' 'md5sum' 'sudo' 'screen' 'git' 'joe')

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

# -- usage
usage () {
USAGE=\
"Usage: install -h|-s (clean|skipdeps|default|home|git|custom <branch> <location>)

  Options
    -h       - This help screen
    -s       - Skip dependencies
  
  Commands
    
    clean                            - Remove zshbop
    default                          - Default install
    home                             - Install in home directory
    git                              - Install in ~/git with dev branch
    custom <branch> <location>		 - Custom install
                                            branch   - m=main d=dev
                                            location - h=home s=system g=~/git
                   
Version: ${VERSION}
"
echo "$USAGE"
}

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
        PKG_MANAGER="sudo apt install $@"
	elif [ -x "$(command -v yum)" ]; then
        echo " - We have yum!"
        PKG_MANAGER="sudo yum install $@"
    elif [ -x "$(command -v brew)" ]; then
        echo " - We have brew!"
        PKG_MANAGER="brew install $@"
    else
    	_error "Can't detect package manager :("
    fi
    
    $(${PKG_MANAGER})
    if [ $? -eq 1 ]; then 
    	_error "$@ install failed...."
        exit 1
    else
	    _success "$@ installed successfully"
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
				if [[ $? -ge "1" ]]; then
					_error "Cloning failed"
					exit 1
				else
					_succes "Cloning completed"
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
		echo " - Cloning into $SYSTEM/zshbop\n"
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
	
	_running "Copying $SYSTEM/zshbop/.zshrc into ~/"
	cp $SYSTEM/zshbop/.zshrc ~/.zshrc
	if [[ $? -ge "1" ]]; then
		_error "Failed to copy $SYSTEM/zshbop/.zshrc into ~/"
		exit 1
	else
		_success "Copied $SYSTEM/zshbop/.zshrc to ~/.zshrc"
	fi
}		

# -------
# -- Main
# -------

    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
    key="$1"

    case $key in
		-h|--help)
        HELP="1"
        shift # past argument
        ;;
        -s|--skipdep)
        SKIPDEP="1"
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters

# -- set $CMD
CMD="$1"

# -- Pre-flight Check
if [[ $SKIPDEP == "0" ]]; then
    _running "Running pre-flight Check"
    flight_check
else
    _running "Skipping pre-flight check"
fi

# -- help
if [[ $HELP == "1" ]];then
    usage
    exit
# -- clean
elif [[ $CMD == "clean" ]]; then
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
# -- default
elif [[ $CMD == "default" ]]; then
	INSTALL=d
# -- home
elif [[ $CMD == "home" ]]; then
    INSTALL=c
    BRANCH=m
    INSTALL_LOCATION=h
# -- git
elif [[ $CMD == "git" ]]; then
	INSTALL=c
	BRANCH=d
	INSTALL_LOCATION=g
elif [[ $CMD == "custom" ]]; then
	_running "Doing a custom install"
	if [[ -z $2 ]] || [[ -z $3 ]]; then
		usage
		exit 1
	else
		INSTALL=c
		BRANCH="$2"
		INSTALL_LOCATION="$3"
	fi
else
	install_method
fi

# -- install start
_running "Begin Install - $INSTALL/$BRANCH/$INSTALL_LOCATION"


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
