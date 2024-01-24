#!/usr/bin/env bash
# ------------------------
# -- zshbop Install script
# ------------------------

##################################
# -- Variables
##################################
VERSION="1.0.0"
SKIP_DEP="0"
SKIP_OPTIONAL="0"
HELP="0"
INSTALL_CUSTOM_PATH=""
SYSTEM_WRITBALE="0"
HOME_WRITABLE="0"
TMP_WRITEABLE="0"

# -- Detect OS for Ubuntu and Version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID    
else
    _error "Can't detect OS"
    exit 1
fi

# -- Required Software
REQUIRED_SOFTWARE=('git' 'wget' 'curl' 'sudo')

# -- Optional Software
OPTIONAL_SOFTWARE=('jq' 'curl' 'sudo' 'screen' 'wget' 'joe')
OPTIONAL_SOFTWARE+=('dnsutils' 'net-tools' 'dmidecode' 'virt-what' 'wget')
OPTIONAL_SOFTWARE+=('unzip' 'zip' 'bc' 'whois' 'telnet' 'ncdu')
OPTIONAL_SOFTWARE+=('traceroute' 'tree' 'mtr' 'ncdu' 'fpart' 'ucommon-utils')
OPTIONAL_SOFTWARE+=('pwgen' 'tree' 'htop' 'iftop' 'iotop' 'lsof')


# -- Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
BLUEBG="\033[0;44m"
GREENBG="\033[0;42m"
DARKGREYBG="\033[0;100m"
DARKGREY="\033[0;90m"
ECOL="\033[0;0m"

##################################
# -- Core Message Functions
##################################
_error () { echo -e "${RED}** ERROR ** - ${*} ${ECOL}"; }
_warning () { echo -e "${YELLOW}** WARNING ** - ${*} ${ECOL}"; }
_success () { echo -e "${GREEN}** SUCCESS ** - ${*} ${ECOL}"; }
_running () { echo -e "${BLUEBG}* ${*} *${ECOL}"; }
_loading () { echo -e "${DARKGREY}${*}${ECOL}"; }
_install () { echo -e "${GREENBG}${*}${ECOL}"; }
_debug () { if [[ $DEBUG == "1" ]]; then echo -e "${CYAN}*** DEBUG: ${*}${ECOL}" >&2; fi; }
_yellow () { echo -e "${YELLOW}${*}${ECOL}"; }


##################################
# -- Core Functions
##################################

# --------------------------------
# -- usage
# --------------------------------
usage () {
USAGE=\
"Usage: install -h|-s (clean|skipdeps|default|home|git|)|(custom <branch> <location>)

  Options
    -h          - This help screen
    -s          - Skip all dependencies
    -o          - Skip optional software check
    -d          - Debug mode

  Commands

    clean                         - Remove zshbop
    default                       - Default install
    home                          - Install in home directory
    git                           - Install in ~/git with dev branch
    custom <branch> <location>    - Custom install
    
  Custom Install: * Note: Custom install skips optional software check
    branch (main|next-release)
    location (home|system|git) 
        - home = \$HOME/zshbop
        - systen = /usr/local/sbin/zshbop
        - git = \$HOME/git/zshbop

>> zshbop Install Script Version: ${VERSION}
>> Detected OS Version: Flavour:${OS} Ver:${VER}
"
echo "$USAGE"
}
# --------------------------------
# -- zshbop_banner
# --------------------------------
function zshbop_banner () {
    echo "           _      _                   ";
    echo "          | |    | |                  ";
    echo " ____ ___ | |__  | |__    ___   _ __  ";
    echo "|_  // __|| '_ \ | '_ \  / _ \ | '_ \ ";
    echo " / / \__ \| |_) || |_) || (_) || |_) |";
    echo "/___||___/|_.__/ |_.__/  \___/ | .__/ ";
    echo "                               | |    ";
    echo "                               |_|    ";
}

##################################
# -- Functions
##################################

# -----------------------------------------------
# -- check_package
# -----------------------------------------------
function check_package () {
    local PACKAGE_LIST=("$@")
    PACKAGE_INSTALL=()
    for PACKAGE in "${PACKAGE_LIST[@]}"; do
        # -- Use dpkg to check if package is installed
        MSG+="Checking $PACKAGE"
        if ! dpkg -s $PACKAGE >/dev/null 2>&1; then
            # -- Check if $PACKAGE is in $PATH
            if ! [ -x "$(command -v $PACKAGE)" ]; then
                _error "$PACKAGE not in \$PATH and not installed via dpkg."
                PACKAGE_INSTALL+=("$PACKAGE")
            else
                _success "$PACKAGE is in \$PATH"
            fi
        else
            _success "$PACKAGE installed"
        fi
    done
}

# -----------------------------------------------
# -- check_zsh
# -----------------------------------------------
function _check_zsh () {
    # -- Check if zsh is installed
    _running "Checking if zsh is installed...."
    if ! [ -x "$(command -v zsh)" ]; then
        _error "zsh is not installed."
        echo -n "Do you want to install zsh via (s)udo or (b)inary? (s/b): "
        read ZSH_INSTALL
        # -- Confirm if sudo or binary install
        if [ "$ZSH_INSTALL" == "s" ] || [ "$ZSH_INSTALL" == "S" ]; then
            _loading "Installing zsh via sudo"
            install_package zsh
        elif [ "$ZSH_INSTALL" == "b" ] || [ "$ZSH_INSTALL" == "B" ]; then
            _loading "Installing zsh via binary"

            # -- Ask where to install zsh binary and loop until valid path is writable, ask five times then exit
            echo -n "Where should we install zsh?: "
            read ZSH_INSTALL_PATH
            while [[ ! -w $ZSH_INSTALL_PATH ]]; do
                _error "Can't write to $ZSH_INSTALL_PATH"
                echo -n "Where should we install zsh?: "
                read ZSH_INSTALL_PATH
                ((i++)) && ((i==5)) && _error "Can't write to $ZSH_INSTALL_PATH, exiting." && exit 1
            done

            # -- Download zsh binary
            # -- Resolve $ZSH_INSTALL_PATH to absolute path
            ZSH_INSTALL_PATH=$(cd $ZSH_INSTALL_PATH && pwd)
            echo "Downloading zsh binary to $ZSH_INSTALL_PATH"
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)" -- -d $ZSH_INSTALL_PATH -q -e no
            if [[ $? -gt 0 ]]; then
                _error "zsh binary install failed...."
                exit 1
            else
                _success "zsh binary installed successfully"
            fi
        fi
    else
        _success -e "- zsh is installed!"
    fi 
}

# -----------------------------------------------
# -- _check_git
# -----------------------------------------------
_check_git () {
    # -- Check it see if git is installed
    _running "Checking if git is installed...."
    if ! [ -x "$(command -v git)" ]; then
        _error "git is not installed."
        echo "Do you want to install git via (s)udo?"
        read GIT_INSTALL
        # -- Confirm if sudo or binary install
        if [ "$GIT_INSTALL" == "s" ] || [ "$GIT_INSTALL" == "S" ]; then
            _loading "Installing git via sudo"
            install_package git
        else 
            _error "Invalid choice, exiting."
            exit 1
        fi
    else
        _success "git is installed!"
    fi
}

# -----------------------------------------------
# -- _check_env
# -----------------------------------------------
_check_env () {
    # -- Check if environment is writable
    _running "Checking if \$HOME:$HOME is writable...."
    if [[ -w $HOME ]]; then
        _success " - $HOME is writable!"
        HOME_WRITABLE="1"
    else
        _error " - $HOME is not writable."
        HOME_WRITABLE="0"
    fi

    # -- Checking if /usr/local/sbin is writable
    _running "Checking if /usr/local/sbin is writable...."
    if [[ -w /usr/local/sbin ]]; then
        _success " - /usr/local/sbin is writable!"
        SYSTEM_WRITBALE="1"
    else
        _error " - /usr/local/sbin is not writable."
        SYSTEM_WRITBALE="0"
    fi

    # -- Check if we can write to $HOME/tmp
    _running "Checking if $HOME/tmp is writable...."
    if [[ -w $HOME/tmp ]]; then
        _success " - $HOME/tmp is writable!"
        TMP_WRITEABLE="1"
    else
        _error " - $HOME/tmp is not writable."
        TMP_WRITEABLE="0"
    fi

}
# -----------------------------------------------
# -- pre_flight_check
# -----------------------------------------------
function pre_flight_check () {
    local DO_INSTALL=() REQUIRED_INSTALL OPTIONAL_INSTALL
    zshbop_banner
    # -- Pre-flight Check
    _running "- Running pre-flight Check"
    
    # -- Skip dependencies
    if [[ $SKIP_DEP == "0" ]]; then
        # -- Check if zsh is installed
        _check_zsh

        # -- Check if git is installed
        _check_git

        # -- Check if $REQUIRED_SOFTWARE packages are installed with apt.
        _running "- Checking if any required software needs to be installed"        
        _debug "\$REQUIRED_SOFTWARE: ${REQUIRED_SOFTWARE[*]}"
        check_package "${REQUIRED_SOFTWARE[@]}"         

        # -- Ask if you want to install the required software
        if [[ ${#PACKAGE_INSTALL[@]} -eq 0 ]]; then
            _loading "- No required software to install"
        else
            echo "Required Packages: ${PACKAGE_INSTALL[*]}"
            echo ""
            read -p "Do you want to install the software above? It's required. (y/n): " REQUIRED_CHOICE

            # -- Install Required Software
            if [ "$REQUIRED_CHOICE" == "y" ] || [ "$REQUIRED_CHOICE" == "Y" ]; then
                install_package "${PACKAGE_INSTALL[@]}"
            elif [ "$REQUIRED_CHOICE" == "n" ] || [ "$REQUIRED_CHOICE" == "N" ]; then
                _loading "Not installing the required software exiting..."
                exit 1
            else
                _error "Invalid choice. Please enter 'y' or 'n'."
            fi
        fi

        # -- Check if $OPTIONAL_SOFTWARE packages are installed with apt.        
        if [[ $SKIP_OPTIONAL == 0 ]]; then
            # -- Check if $OPTIONAL_SOFTWARE packages are installed with apt.
            _running "Checking if any optional software needs to be installed"        
            _debug "\$OPTIONAL_SOFTWARE: ${OPTIONAL_SOFTWARE[*]}"
            check_package "${OPTIONAL_SOFTWARE[@]}"             

            if [[ ${#PACKAGE_INSTALL[@]} -eq 0 ]]; then
                _loading "No optional software to install"
            else
                echo "Required Packages: ${PACKAGE_INSTALL[*]}"
                echo ""
                read -p "Do you want to install the software above? It's optional. (y/n): " OPTIONAL_CHOICE

                # -- Install Optional Software
                if [ "$OPTIONAL_CHOICE" == "y" ] || [ "$OPTIONAL_CHOICE" == "Y" ]; then
                    install_package "${PACKAGE_INSTALL[@]}"
                elif [ "$OPTIONAL_CHOICE" == "n" ] || [ "$OPTIONAL_CHOICE" == "N" ]; then
                    _loading "Not installing the optional software...continuing"
                else
                    _error "Invalid choice. Please enter 'y' or 'n'."
                fi
            fi
        else
            _loading "- Skipping optional software check"
        fi
	else
	    _loading "- Skipping pre-flight check and installing required packages."
	fi
}

# --------------------------------
# -- install_package - install packages.
# --------------------------------
function install_package () {
    # -- Checking if sudo is installed
    if ! [ -x "$(command -v sudo)" ]; then
        _loading "sudo is not installed, installing sudo"
        install_package sudo
    fi

    _debug "Installing ${*}"
	# Checking what package manager we have
    _loading "Checking what package manager we have...."
    if [ -x "$(command -v apt-get)" ]; then
        echo " - We have apt!"
        sudo apt-get update
        sudo apt install --no-install-recommends -y "${*}"
	elif [ -x "$(command -v yum)" ]; then
        echo " - We have yum!"
        sudo yum install "${*}"
    elif [ -x "$(command -v brew)" ]; then
        echo " - We have brew!"
        brew install "${*}"
    else
    	_error "Can't detect package manager :("
    fi
    
    if [ $? -gt 0 ]; then
    	_error "${*} install failed...."
        exit 1
    else
	    _success "${*} installed successfully"
    fi
}

# --------------------------------
# -- check_zsh_default
# --------------------------------
function check_zsh_default () {
        # Check if zsh is the default shell
        _running "Checking if zsh is the default shell...."
        if ! [[ $SHELL == *"zsh" ]]; then
                _warning " Your default shell isn't zsh, use chsh to change it to zsh."
        else
                _success -e "- ZSH is your default shell!"
        fi
}

# --------------------------------
# -- install_method - how do you want to install zshbop?
# --------------------------------
function install_method () {
    # -- Print ZSHBOP banner
    zshbop_banner
	echo ""

    _install "Starting zshbop install"

    # -- Install method
    if [[ $SYSTEM_WRITBALE == "1" ]]; then        
        echo "Install (d)efaults or (c)ustomize? (d/c)?"
    	read INSTALL
    else
        _error "Can't write to /usr/local/sbin, proceeding with custom install."
        INSTALL="c"
    fi

    # -- Setup variables for install method choosen
	if [ $INSTALL == "d" ]; then
        # -- Default install = system wide, main branch
        INSTALL_LOCATION="system"
		BRANCH="master"
	elif [ $INSTALL == "c" ]; then
        # -- Custom install
        echo "Where do you want to install?"
        echo ""

        [[ $SYSTEM_WRITBALE == "1" ]] && echo "(s) = System path /usr/local/sbin/zshbop"
        [[ $HOME_WRITABLE == "1" ]] && echo "(h) = Home path \$HOME/zshbop"
        [[ $HOME_WRITABLE == "1" ]] && echo "(g) = Git path \$HOME/git/zshbop"
        echo "(c) = Custom path ex. /opt"
        echo ""
        echo "Enter Install Type:"
        read INSTALL_LOCATION
        [[ $INSTALL_LOCATION == "s" ]] && INSTALL_LOCATION="system"
        [[ $INSTALL_LOCATION == "h" ]] && INSTALL_LOCATION="home"
        [[ $INSTALL_LOCATION == "g" ]] && INSTALL_LOCATION="git"
        if [[ $INSTALL_LOCATION == "c" ]]; then
            INSTALL_LOCATION="custom"
            echo "Enter custom path:"
            read INSTALL_CUSTOM_PATH
        fi

        echo ""
        echo "Branch (m)ain, (d)ev, (n)ext-release Branch? (d/m/n)"
        read BRANCH
        [[ $BRANCH == "m" ]] && BRANCH="main"
        [[ $BRANCH == "d" ]] && BRANCH="dev"
        [[ $BRANCH == "n" ]] && BRANCH="next-release"        
	fi
}

# --------------------------------
# -- clone_repository
# --
# -- $1 = BRANCH
# -- $2 = INSTALL_LOCATION
# -- $3 = INSTALL_PATH
# --------------------------------
function clone_repository () {
    local GIT_CMD="git"
    local BRANCH=$1
    local INSTALL_LOCATION=$2
    local INSTALL_PATH=$3
    
    # -- Check the install location and use sudo if needed
    _debug "INSTALL_LOCATION: $INSTALL_LOCATION INSTALL_PATH: $INSTALL_PATH BRANCH: $BRANCH"

    if [[ $INSTALL_LOCATION == "system" ]]; then        
        # -- Check if running as root
        _loading "- Checking if running as root..."
        if [[ $EUID -ne 0 ]]; then
            _warning "Not running as root, cloning repository into $INSTALL_PATH using sudo"
            GIT_CMD="sudo git"
        else
            _loading "- Running as root, cloning repository into $INSTALL_PATH"
        fi        
    fi

    # -- Check if directory exists
    if [[ ! -d $INSTALL_PATH ]]; then
        # -- Clone repository using $BRANCH
        _running "Start Cloning repository into $1..."
        
        if [[ $BRANCH == "main" ]]; then
            $(${GIT_CMD} clone https://github.com/jordantrizz/zshbop.git $INSTALL_PATH)
        elif [[ $BRANCH == "dev" ]]; then
            $(${GIT_CMD} clone --branch dev https://github.com/jordantrizz/zshbop.git $INSTALL_PATH)
        elif [[ $BRANCH == "next-release" ]]; then
            $(${GIT_CMD} clone --branch next-release https://github.com/jordantrizz/zshbop.git $INSTALL_PATH)
        else
            _error "Invalid branch - $BRANCH"
            exit 1
        fi

        # -- Check to see if the clone was successful
        if [[ $? -ge "1" ]]; then
            _error "Cloning failed"
            exit 1
        else
            _success "Cloning completed"
        fi
    else
            _error "Directory $INSTALL_PATH exists...exiting."
            exit 1
    fi
}

# -----------------------------------------------
# -- setup_zshbop
# --
# -- $1 = branch
# -- $2 = install location
# -----------------------------------------------
function setup_zshbop() {
    # -- Setup ZSH
    local BRANCH=$1
    local INSTALL_LOCATION=$2
    _running "Begin Install - $BRANCH/$INSTALL_LOCATION"

    if [[ $INSTALL_LOCATION == "system" ]]; then
        INSTALL_PATH="/usr/local/sbin"
    elif [[ $INSTALL_LOCATION == "home" ]]; then
        INSTALL_PATH="$HOME"
    elif [[ $INSTALL_LOCATION == "git" ]]; then
        INSTALL_PATH="$HOME/git"
    elif [[ $INSTALL_LOCATION == "custom" ]]; then
        INSTALL_PATH="$INSTALL_CUSTOM_PATH"
    else
        _error "Invalid install location"
        exit 1
    fi

    # -- Confirm that we can write to $INSTALL_PATH
    _loading "- Checking if we can write to $INSTALL_PATH"
    if [[ -w $INSTALL_PATH ]]; then
        _success "- We can write to $INSTALL_PATH"
    else
        _error "- We can't write to $INSTALL_PATH"
        exit 1
    fi

    # -- Clone Repository
    _loading "- Cloning repository $BRANCH into $INSTALL_PATH..."
    clone_repository "$BRANCH" "$INSTALL_LOCATION" "$INSTALL_PATH/zshbop"

    # -- Setup .zshrc
     _loading "- Setting up system based .zshrc..."
    
    # -- Check if we can write to .zshrc
    if [[ -w $HOME/.zshrc ]]; then
        _success "- We can write to $HOME/.zshrc"
    else
        _error "- We can't write to $HOME/.zshrc, you will need to invoke zshbop some other way"
        exit 1
    fi

    # -- Check if .zshrc has zshbop.zsh in it
    if ! [ -f $HOME/.zshrc ]; then
        echo "source $INSTALL_PATH/zshbop/zshbop.zsh" >> $HOME/.zshrc
        _success "- ZSH in-place at $INSTALL_PATH, type zsh to start your shell\n"
    else
        _error "- There's already a .zshrc in-place, exiting.\n"
        echo "You can add the following to your .zshrc file:"
        echo ""
        echo "source $INSTALL_PATH/zshbop/zshbop.zsh"
        echo " or"
        echo " echo \"source $INSTALL_PATH/zshbop/zshbop.zsh\" >> ~/.zshrc"
        echo ""
        echo "Then type zsh to start your shell"
        echo ""
        exit 1
    fi
    
    _success "Installation complete."
}

# -------------------------------------------------------------------------------------------------
# -- Main
# -------------------------------------------------------------------------------------------------

# -- Parse Arguments
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
    SKIP_DEP="1"
    shift # past argument
    ;;
    -o|--optional)
    SKIP_OPTIONAL="1"
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
		_loading "Aboring....Goodbye!"
		exit
	fi
# -- default
elif [[ $CMD == "default" ]]; then
	pre_flight_check	
    BRANCH=main
    INSTALL_LOCATION=system
    setup_zshbop $BRANCH $INSTALL_LOCATION 
# -- home
elif [[ $CMD == "home" ]]; then
	pre_flight_check    
    BRANCH=main
    INSTALL_LOCATION=home
    setup_zshbop $BRANCH $INSTALL_LOCATION 
# -- git
elif [[ $CMD == "git" ]]; then
	pre_flight_check	
	BRANCH=dev
	INSTALL_LOCATION=git
    setup_zshbop $BRANCH $INSTALL_LOCATION 
elif [[ $CMD == "custom" ]]; then
	_running "Custom install"
	if [[ -z $2 ]] || [[ -z $3 ]]; then
		usage
		exit 1
	else		
        pre_flight_check	
		BRANCH="$2"
		INSTALL_LOCATION="$3"
        setup_zshbop $BRANCH $INSTALL_LOCATION 
	fi
else
    if [[ -n $CMD ]]; then
        usage
        exit 1
    fi
    pre_flight_check
	install_method
    setup_zshbop $BRANCH $INSTALL_LOCATION 
fi
