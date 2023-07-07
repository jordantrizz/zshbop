#!/usr/bin/env bash
# ------------------------
# -- zshbop Install script
# ------------------------

#---------------------------------
# -- Variables
#---------------------------------
VERSION="0.0.3"
SKIPDEP="0"
HELP="0"
# TODO - Add install to zshbop.zsh
REQUIRED_SOFTWARE=('jq' 'curl' 'zsh' 'git' 'md5sum' 'sudo' 'screen' 'git' 'joe' 'dnsutils' 
    'net-tools' 'dmidecode' 'virt-what' 'wget' 'unzip' 'zip' 'python3' 'python3-pip'
    'bc' 'whois' 'telnet' 'lynx' 'traceroute' 'mtr' 'mosh' 'tree' 'ncdu' 'fpart'
    'jq')
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

#---------------------------------
# -- Core Functions
#---------------------------------
# -- Messages
_error () { echo -e "${RED}** ERROR ** - ${*} ${ECOL}"; }
_warning () { echo -e "${YELLOW}** ERROR ** - ${*} ${ECOL}"; }
_success () { echo -e "${GREEN}** SUCCESS ** - ${*} ${ECOL}"; }
_running () { echo -e "${BLUEBG}${*}${ECOL}"; }
_install () { echo -e "${GREENBG}${*}${ECOL}"; }
_debug () { if [[ $DEBUG == "1" ]]; then echo -e "${CYAN}*** DEBUG: ${*}${ECOL}"; fi; }

# -- usage
usage () {
USAGE=\
"Usage: install -h|-s (clean|skipdeps|default|home|git|custom <branch> <location>)

  Options
    -h       - This help screen
    -s       - Skip dependencies
    -d       - Debug mode

  Commands

    clean                            - Remove zshbop
    default                          - Default install
    home                             - Install in home directory
    git                              - Install in ~/git with dev branch
    custom <branch> <location>		 - Custom install
                                            branch   - m=main d=dev b=bleeding
                                            location - h=home s=system g=~/git

Version: ${VERSION}
"
echo "$USAGE"
}

# -- zshbop_banner
zshbop_banner () {
    echo "           _      _                   ";
    echo "          | |    | |                  ";
    echo " ____ ___ | |__  | |__    ___   _ __  ";
    echo "|_  // __|| '_ \ | '_ \  / _ \ | '_ \ ";
    echo " / / \__ \| |_) || |_) || (_) || |_) |";
    echo "/___||___/|_.__/ |_.__/  \___/ | .__/ ";
    echo "                               | |    ";
    echo "                               |_|    ";
}

#---------------------------------
# -- Functions
#---------------------------------

# -- flight_check
pre_flight_check () {
    # -- Pre-flight Check
    _debug "Running pre_flight_check"
    if [[ $SKIPDEP == "0" ]]; then
        _running "Running pre-flight Check"
        local TOOLS_INSTALL

        _debug "Checking if required software are installed"
        _debug "\$REQUIRED_SOFTWARE: ${REQUIRED_SOFTWARE[*]}"
        for tool in "${REQUIRED_SOFTWARE[@]}"; do
                if ! [ -x "$(command -v $tool)" ]; then
                        _error "$tool is not installed."
                        TOOLS_INSTALL+=("$tool")
                else
                        TOOL_PATH=`which $tool`
                        _debug "$tool is installed in $TOOL_PATH"
                fi
        done
        _debug "\$TOOLS_INSTALL: ${TOOLS_INSTALL[*]}"
        if [[ ${#TOOLS_INSTALL[@]} -eq 0 ]]; then
            _debug "No software to install, proceeding."
        else
            _running "Installing required packages..."
            echo "   Packages: ${TOOLS_INSTALL[*]}"
            echo ""
            read -p "Do you want to install the software above? (y/n): " choice
            if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
                echo ""
                echo "${YELLOW}****************************************************${ECOL}"
                sudo apt-get update
                sudo apt-get install -y --no-install-recommends "${TOOLS_INSTALL[@]}"
                echo "${YELLOW}****************************************************${ECOL}"
                echo ""
            elif [ "$choice" == "n" ] || [ "$choice" == "N" ]; then
                echo "Not installing the software...continuing"
            else
                echo "Invalid choice. Please enter 'y' or 'n'."
            fi
        fi
	else
	    _running "Skipping pre-flight check and installing required packages."
	fi
}

# -- pkg_install - install packafges.
pkg_install () {
	# Checking what package manager we have
    _running "Checking what package manager we have...."
    if [ -x "$(command -v apt-get)" ]; then
        echo " - We have apt!"
        sudo apt install --no-install-recommends "${*}"
	elif [ -x "$(command -v yum)" ]; then
        echo " - We have yum!"
        sudo yum install "${*}"
    elif [ -x "$(command -v brew)" ]; then
        echo " - We have brew!"
        brew install "${*}"
    else
    	_error "Can't detect package manager :("
    fi

    $(${PKG_MANAGER})
    if [ $? -eq 1 ]; then
    	_error "${*} install failed...."
        exit 1
    else
	    _success "${*} installed successfully"
    fi
}

# -- install_method - how do you want to install zshbop?
install_method () {
    # -- Print ZSHBOP banner
    zshbop_banner
	echo ""
    
    # -- Install method
    _install "Starting zshbop install"
    echo "Install (d)efaults or (c)ustomize? (d/c)?"
	read INSTALL

    # -- Setup variables for install method choosen
	if [ $INSTALL == "d" ];then
        # -- Default install = system wide, main branch
        INSTALL_LOCATION=system
		BRANCH=m
	elif [ $INSTALL == "c" ]; then
        # -- Custom install
        echo "Do you want to install system wide or home only? (s/h/g)"
        read INSTALL_LOCATION
        [[ $INSTALL_LOCATION == "s" ]] && INSTALL_LOCATION=system
        [[ $INSTALL_LOCATION == "h" ]] && INSTALL_LOCATION=home
        [[ $INSTALL_LOCATION == "g" ]] && INSTALL_LOCATION=git
        
        echo "Branch (m)ain, (d)ev, (n)ext-release Branch? (d/m/n)"
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
            elif [[ $BRANCH == "n" ]]; then
                git clone --branch next-release https://github.com/jordantrizz/zshbop.git $1
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


# -- setup_zsh
setup_zsh() {
    # -- Setup ZSH
    SETUP_SYSTEM_PATH="/usr/local/sbin"
    SETUP_HOME_PATH="$HOME"
    SETUP_GIT_PATH="$HOME/git"    

    if [[ $INSTALL_LOCATION == "system" ]]; then
        SETUP_PATH=$SETUP_SYSTEM_PATH
    elif [[ $INSTALL_LOCATION == "home" ]]; then
        SETUP_PATH=$SETUP_HOME_PATH
    elif [[ $INSTALL_LOCATION == "git" ]]; then
        SETUP_PATH=$SETUP_GIT_PATH
    else
        _error "Invalid install location"
        exit 1
    fi

    # -- Clone Repository
    clone_repository "$SETUP_PATH/zshbop"

    # -- Setup .zshrc
    if ! [ -f $HOME/.zshrc ]; then
        echo "source $SETUP_PATH/zshbop/zshbop.zsh" >> $HOME/.zshrc
        _success "- ZSH in-place at $SETUP_PATH, type zsh to start your shell\n"
    else
        _error "- There's already a .zshrc in-place, exiting.\n"
        echo "You can add the following to your .zshrc file:"
        echo ""
        echo "source $SETUP_PATH/zshbop/zshbop.zsh"
        echo ""
        echo "Then type zsh to start your shell"
        echo ""
        exit 1
    fi

    # Confirm that /usr/local/sbin exists
	_running "Setting up system based .zshrc..."
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

#---------------------------------
#---------------------------------
# -- Main
#---------------------------------
#---------------------------------

#---------------------------------
# -- Parse Arguments
#---------------------------------

_debug "ARGS: ${*}"

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
    -d)
    DEBUG="1"
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

# -- help
if [[ $HELP == "1" ]];then
    usage
    exit
# -- clean
elif [[ $CMD == "clean" ]]; then
	_running "Removing zshbop from system"
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
	pre_flight_check
	INSTALL=d
# -- home
elif [[ $CMD == "home" ]]; then
	pre_flight_check
    INSTALL=c
    BRANCH=m
    INSTALL_LOCATION=home
# -- git
elif [[ $CMD == "git" ]]; then
	pre_flight_check
	INSTALL=c
	BRANCH=d
	INSTALL_LOCATION=git
elif [[ $CMD == "custom" ]]; then
	_running "Doing a custom install"
	if [[ -z $2 ]] || [[ -z $3 ]]; then
		usage
		exit 1
	else
		pre_flight_check
		INSTALL=c
		BRANCH="$2"
		INSTALL_LOCATION="$3"
	fi
else
    pre_flight_check
	install_method
fi

#---------------------------------
# -- Start Install
#---------------------------------

_running "Begin Install - $INSTALL/$BRANCH/$INSTALL_LOCATION"

if [[ $INSTALL == "d" ]]; then
	setup_zsh system
elif [[ $INSTALL == "c" ]]; then
    setup_zsh $INSTALL_LOCATION
fi

_success "Installation complete."
