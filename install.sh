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
ZSHBOP_SEARCH_LOCATIONS=("~/zshbop" "/usr/local/sbin/zshbop" "$HOME/git/zshbop")

# -- Required Software
REQUIRED_SOFTWARE=('git' 'wget' 'curl')

# -- Optional Software
OPTIONAL_SOFTWARE=('jq' 'curl' 'sudo' 'screen' 'wget' 'joe')
OPTIONAL_SOFTWARE+=('dnsutils' 'net-tools' 'dmidecode' 'virt-what' 'wget')
OPTIONAL_SOFTWARE+=('unzip' 'zip' 'bc' 'whois' 'telnet' 'ncdu')
OPTIONAL_SOFTWARE+=('traceroute' 'tree' 'mtr' 'ncdu' 'ucommon-utils')
OPTIONAL_SOFTWARE+=('pwgen' 'tree' 'htop' 'iftop' 'iotop' 'lsof')


# -- Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
BLACK="\033[0;30m"
BLUE="\033[0;34m"
LIGHTBLUE="\033[1;34m"
YELLOWBG="\033[0;43m"
BLUEBG="\033[0;44m"
GREENBG="\033[0;42m"
DARKGREYBG="\033[0;100m"
DARKGREY="\033[0;90m"
ECOL="\033[0;0m"

##################################
# -- Core Message Functions
##################################
_error () { echo -e "${RED}  ** ERROR ** - ${*} ${ECOL}"; }
_warning () { echo -e "${YELLOW}  ** WARNING ** - ${*} ${ECOL}"; }
_success () { echo -e "${GREEN}  ** SUCCESS ** - ${*} ${ECOL}"; }
_running () { echo -e "${DARKGREYBG}${YELLOW}* ${*} *${ECOL}"; }
_running2 () { echo -e "${LIGHTBLUE}* ${*} *${ECOL}"; }
_loading () { echo -e "${DARKGREY}  -- ${*}${ECOL}"; }
_install () { echo -e "${YELLOWBG}${BLACK}${*}${ECOL}"; }
_debug () { if [[ $DEBUG == "1" ]]; then echo -e "${CYAN}*** DEBUG: ${*}${ECOL}" >&2; fi; }
_yellow () { echo -e "${YELLOW}${*}${ECOL}"; }
_divider () { echo -e "${YELLOWBG}                                      ${ECOL}"; }

##################################
# -- Core Functions
##################################

# =====================================
# -- usage
# =====================================
usage () {
USAGE=\
"Usage: install -h|-s|-o|-d (clean|search|default|home|git|)|(custom <branch> <location>)

  Options
    -h          - This help screen
    -s          - Skip all dependencies
    -o          - Skip optional software check
    -d          - Debug mode

  Commands

    clean                         - Remove zshbop
    search                        - Search for zshbop installs
    default                       - Default install
    home                          - Install in home directory
    git                           - Install in ~/git with dev branch
    custom <branch> <location>    - Custom install
    env                           - Setup environment variables in .zshrc
    
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

# =====================================
# -- zshbop_banner
# =====================================
function zshbop_banner () {
    _divider
    echo "           _      _                   ";
    echo "          | |    | |                  ";
    echo " ____ ___ | |__  | |__    ___   _ __  ";
    echo "|_  // __|| '_ \ | '_ \  / _ \ | '_ \ ";
    echo " / / \__ \| |_) || |_) || (_) || |_) |";
    echo "/___||___/|_.__/ |_.__/  \___/ | .__/ ";
    echo "                               | |    ";
    echo "                               |_|    ";
    _divider
    echo ""
}

##################################
# -- Functions
##################################

# =====================================
# -- _clean_zshbop
# =====================================
function _clean_zshbop () {    
    local FOUND_INSTANCE=""
    echo ""
    _running2 "Removing zshbop from system"    
    
    _loading "Searching for zshbop in $ZSHBOP_SEARCH_LOCATIONS"
    for INSTANCE in ${ZSHBOP_SEARCH_LOCATIONS[@]}; do
        if [[ -d $INSTANCE ]]; then
            _success "Found zshbop in $INSTANCE"
            FOUND_INSTANCE="$INSTANCE"            
        else
            _loading "No zshbop install found in $INSTANCE"
        fi
    done
    
    if [[ -n $FOUND_INSTANCE ]]; then
        echo ""
        echo -n "Remove $FOUND_INSTANCE - Continue (y/n)?: "
        read CLEAN
        echo ""
        if [[ $CLEAN == "y" ]]; then
            _running2 "Removing $FOUND_INSTANCE"            
            rm -rf $FOUND_INSTANCE            
            if [[ $?  ]]; then
                _success "Removed $FOUND_INSTANCE"
                exit
            else
                _error "Failed to remove $FOUND_INSTANCE"
                exit
            fi            
        else
            _loading "Aboring....Goodbye!"
            exit
        fi
    else        
        echo ""
        _error "No zshbop installs found, exiting."
        exit
    fi
}

# =====================================
# -- _search_zshbop $MODE
# =====================================
function _search_zshbop () {
    local MODE=${1:=0}
    local ZSHBOP_DIR ZSHBOP_LOCATION

    if [[ $MODE == 0 ]]; then
        _running "Searching for zshbop installs in $ZSHBOP_SEARCH_LOCATIONS"    
        local ZSHBOP_LOCATIONS=("~/zshbop" "/usr/local/sbin/zshbop" "$HOME/git/zshbop")
        _running "Searching for zshbop installs"
        for ZSHBOP_LOCATION in "${ZSHBOP_LOCATIONS[@]}"; do
            if [[ -d $ZSHBOP_LOCATION ]]; then
                _success "Found zshbop install in $ZSHBOP_LOCATION"
            else
                _error "No zshbop install found in $ZSHBOP_LOCATION"
            fi
        done
    elif [[ $MODE == 1 ]]; then
        # Return full path to detected zshbop install
        for ZSHBOP_LOCATION in "${ZSHBOP_SEARCH_LOCATIONS[@]}"; do
            if [[ -d $ZSHBOP_LOCATION ]]; then
                ZSHBOP_DIR="$ZSHBOP_LOCATION"
                break
            fi            
        done
        if [[ -n $ZSHBOP_DIR ]]; then
            echo "$ZSHBOP_DIR"
        else          
            return 1
        fi
    fi
}

# ================================================
# -- check_package
# ================================================
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
                _debug "$PACKAGE is in \$PATH"
            fi
        else
            _debug "$PACKAGE installed"
        fi
    done
}

# ================================================
# -- _install_zsh - install zsh
# ================================================
function _install_zsh () {
    echo -n "Do you want to install zsh via (p)package or (b)inary? (p/b): "
    read ZSH_INSTALL

    if [ "$ZSH_INSTALL" == "p" ] || [ "$ZSH_INSTALL" == "P" ]; then
        _install_zsh_package
    elif [ "$ZSH_INSTALL" == "b" ] || [ "$ZSH_INSTALL" == "B" ]; then
        _install_zsh_binary
    else 
        _error "Invalid choice, exiting."
        exit 1
    fi
}

# ================================================
# -- _install_zsh_package - install zsh via sudo
# ================================================
function _install_zsh_package () {
    _loading "Installing zsh via package"
    install_package zsh
}

# ================================================
# -- _install_zsh_binary - install zsh binary
# ================================================
function _install_zsh_binary () {
    _loading "Installing zsh via binary"
    # -- Ask where to install zsh binary and loop until valid path is writable, ask five times then exit
    echo -n "Where should we install zsh? (/usr/local): "
    read ZSH_INSTALL_PATH    

    # Check if $ZSH_INSTALL_PATH is empty
    if [[ -z $ZSH_INSTALL_PATH ]]; then
        ZSH_INSTALL_PATH="/usr/local"
    fi

    # Check if $ZSH_INSTALL_PATH is writable
    while [[ ! -w $ZSH_INSTALL_PATH ]]; do
        _error "Can't write to $ZSH_INSTALL_PATH"
        echo -n "Where should we install zsh? (/usr/local): "
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
        _success "zsh binary installed successfully in $ZSH_INSTALL_PATH/bin/zsh"
        ZSH_BIN="$ZSH_INSTALL_PATH/bin/zsh"
        ln -s /usr/local/bin/zsh /usr/bin/zsh
    fi
}

# ================================================
# -- check_zsh
# ================================================
function _check_zsh () {
    # -- Check if zsh is installed
    echo -n "$(_loading "Checking if zsh is installed.")"
    if ! [ -x "$(command -v zsh)" ]; then
        _error "zsh is not installed."
        _install_zsh
    else
        # -- Check if ZSH is at least 5.8
        ZSH_VERSION=$(zsh --version | awk '{print $2}')
        # Split the version into minor and major
        ZSH_MAJOR=$(echo $ZSH_VERSION | cut -d'.' -f1)
        ZSH_MINOR=$(echo $ZSH_VERSION | cut -d'.' -f2)
        if [[ $ZSH_MAJOR -ge 5 ]] && [[ $ZSH_MINOR -ge 8 ]]; then        
            ZSH_BIN=$(which zsh)
            echo " -- $(_success "zsh is installed in $ZSH_BIN! and at least 5.8")"
        else
            _error "zsh is installed but not at least 5.8"
            echo ""
            echo "Do you want to install an updated zsh via binary? (y/n)"
            read ZSH_INSTALL

            if [ "$ZSH_INSTALL" == "y" ] || [ "$ZSH_INSTALL" == "Y" ]; then
                _running "Removing zsh package"
                remove_package zsh
                _running "Installing zsh binary"
                _install_zsh_binary
            elif [ "$ZSH_INSTALL" == "n" ] || [ "$ZSH_INSTALL" == "N" ]; then
                echo "Existing, zsh is not at least 5.8"
            else
                _error "Invalid choice, exiting."
                exit 1
            fi
        fi
    fi 
}

# ================================================
# -- _check_git
# ================================================
_check_git () {
    # -- Check it see if git is installed
    echo -n "$(_loading "Checking if git is installed.") -- "
    if ! [ -x "$(command -v git)" ]; then
        _error "git is not installed."
        _loading "Installing git"
        install_package git        
    else
        _success "git is installed!"
    fi
}

# ================================================
# -- _check_env
# ================================================
_check_env () {
    # -- Check if environment is writable
    _loading "Checking if environment is writable"
    if [[ -w $HOME ]]; then        
        HOME_WRITABLE="1"
    else        
        HOME_WRITABLE="0"
    fi

    # -- Checking if /usr/local/sbin is writable
    if [[ -w /usr/local/sbin ]]; then        
        SYSTEM_WRITBALE="1"
    else        
        SYSTEM_WRITBALE="0"
    fi

    # -- Check if we can write to $HOME/tmp    
    if [[ -w $HOME/tmp ]]; then
        TMP_WRITEABLE="1"
    else
        TMP_WRITEABLE="0"
    fi

    # -- Check if running as root
    if [[ $EUID -ne 0 ]]; then
        _warning "Not running as root, some checks may fail."
        RUNNING_AS_ROOT="0"
    else
        RUNNING_AS_ROOT="1"
    fi

    # -- Check if sudo is installed
    echo -n "$(_loading "Checking if sudo is installed.") -- "
    if ! [ -x "$(command -v sudo)" ]; then
        SUDO_INSTALLED="0"
    else
        SUDO_INSTALLED="1"
    fi

}

# ================================================
# -- pre_flight_check
# ================================================
function pre_flight_check () {
    local DO_INSTALL=() REQUIRED_INSTALL OPTIONAL_INSTALL
    zshbop_banner
    # -- Pre-flight Check
    _running "Running pre-flight Check"
    
    # -- Check environment
    _running2 "Checking environment"
    _check_env
    
    # -- Skip dependencies
    if [[ $SKIP_DEP == "0" ]]; then
        # -- Detect OS for Ubuntu and Version
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID    
        elif [ -f /etc/redhat-release ]; then
            # Fallback for older RHEL/CentOS/CloudLinux systems without os-release
            OS=$(cat /etc/redhat-release | awk '{print $1}')
            VER=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | head -1)
        else
            _error "Can't detect OS"
            exit 1
        fi

        # -- Check if zsh is installed
        _check_zsh

        # -- Check if git is installed
        _check_git

        # -- Check if $REQUIRED_SOFTWARE packages are installed with apt.
        _running2 "Checking if any required software needs to be installed"        
        _debug "\$REQUIRED_SOFTWARE: ${REQUIRED_SOFTWARE[*]}"
        check_package "${REQUIRED_SOFTWARE[@]}"         

        # -- Ask if you want to install the required software
        if [[ ${#PACKAGE_INSTALL[@]} -eq 0 ]]; then
            _loading "No required software to install"
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
            _running2 "Checking if any optional software needs to be installed"        
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
    echo ""
}

# =====================================
# -- install_package - install packages.
# =====================================
function install_package () {
    local PRE_CMD="" CMD=""
    _running "Installing ${*}"

    # sudo or not
    if [[ $RUNNING_AS_ROOT == "0" ]]; then
        PRE_CMD="sudo"
        # Check if sudo available
        if [[ $SUDO_INSTALLED == "0" ]]; then
            _error "sudo is not installed, exiting."
            exit 1
        fi
    fi

	# Checking what package manager we have
    _debug "Checking what package manager we have...."
    if [ -x "$(command -v apt-get)" ]; then
        CMD="$PRE_CMD apt-get install --no-install-recommends -y ${*}"
        _running "Updating apt-get package list...."
        eval $PRE_CMD apt-get update -y
        _running "Running - $CMD "
        eval "$CMD"
	elif [ -x "$(command -v yum)" ]; then
        CMD="$PRE_CMD yum install ${*}"
        _running "Running - $CMD"
        eval "$CMD"
    elif [ -x "$(command -v brew)" ]; then
        CMD="$PRE_CMD brew install ${*}"
        _running "Running - $INSCMDTALL_CMD"
        eval "$CMD"
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

# ================================================
# -- remove_package
# ================================================
function remove_package () {
    local PRE_CMD="" CMD=""
    _running "Removing package ${*}"

    # sudo or not
    if [[ $RUNNING_AS_ROOT == "0" ]]; then
        PRE_CMD="sudo"
        # Check if sudo available 
        if [[ $SUDO_INSTALLED == "0" ]]; then
            _error "sudo is not installed, exiting."
            exit 1
        fi
    fi
    # -- Checking what package manager we have
    _loading "Checking what package manager we have...."

    if [ -x "$(command -v apt-get)" ]; then
        CMD="$PRE_CMD apt-get remove --purge -y ${*}"
        _running "Running - $CMD"
        eval "$CMD"
    elif [ -x "$(command -v yum)" ]; then
        CMD="$PRE_CMD yum remove -y ${*}"
        _running "Running - $CMD"
        eval "$CMD"
    elif [ -x "$(command -v brew)" ]; then
        CMD="$PRE_CMD brew remove ${*}"
        _running "Running - $CMD"
        eval "$CMD"
    else
        _error "Can't detect package manager :("
    fi

    if [ $? -gt 0 ]; then
        _error "$1 remove failed...."
        exit 1
    else
        _success "$1 removed successfully"
    fi
}

# ================================================
# -- check_zsh_default
# ================================================
function check_zsh_default () {
        # Check if zsh is the default shell
        _running "Checking if zsh is the default shell...."
        if ! [[ $SHELL == *"zsh" ]]; then
                _warning " Your default shell isn't zsh, use chsh to change it to zsh."
        else
                _success -e "- ZSH is your default shell!"
        fi
}

# ================================================
# -- install_method - how do you want to install zshbop?
# ================================================
function install_method () {
    # -- Print ZSHBOP banner
    _running "Starting zshbop install"
    echo ""

    echo -n "Install (d)efaults or (c)ustomize? (d/c)?: "
    read INSTALL

    # -- Install method
    if [[ $SYSTEM_WRITBALE == "0" ]]; then        
        _error "Can't write to /usr/local/sbin"
        SYSTEM_PATH_MSG="(s) = System path /usr/local/sbin/zshbop (Not Writable requires sudo)"
        INSTALL="c"
    else
        SYSTEM_PATH_MSG="(s) = System path /usr/local/sbin/zshbop"
    fi

    # -- Check if we can write to $HOME
    if [[ $HOME_WRITABLE == "0" ]]; then
        _error "Can't write to \$HOME, skipping default install and forcing custom install."
        INSTALL="c"
    fi

    # -- Setup variables for install method choosen
	if [ $INSTALL == "d" ]; then
        # -- Default install = system wide, main branch
        INSTALL_LOCATION="system"
		BRANCH="main"
	elif [ $INSTALL == "c" ]; then
        # -- Custom install
        echo ""
        _running "Where do you want to install?"
        echo ""

        echo $SYSTEM_PATH_MSG
        [[ $HOME_WRITABLE == "1" ]] && echo "(h) = Home path \$HOME/zshbop"
        [[ $HOME_WRITABLE == "1" ]] && echo "(g) = Git path \$HOME/git/zshbop"
        echo "(c) = Custom path ex. /opt"
        echo ""
        echo -n "Enter Install Type: "
        read INSTALL_LOCATION
        [[ $INSTALL_LOCATION == "s" ]] && INSTALL_LOCATION="system"
        [[ $INSTALL_LOCATION == "h" ]] && INSTALL_LOCATION="home"
        [[ $INSTALL_LOCATION == "g" ]] && INSTALL_LOCATION="git"
        if [[ $INSTALL_LOCATION == "c" ]]; then
            INSTALL_LOCATION="custom"
            echo -n "Enter custom path: "
            read INSTALL_CUSTOM_PATH
            # -- Resolve $INSTALL_CUSTOM_PATH to absolute path
            INSTALL_CUSTOM_PATH=$(cd $INSTALL_CUSTOM_PATH && pwd)
        fi
        
        echo -n "Branch (m)ain, (d)ev, (n)ext-release Branch? (d/m/n): "
        read BRANCH
        [[ $BRANCH == "m" ]] && BRANCH="main"
        [[ $BRANCH == "d" ]] && BRANCH="dev"
        [[ $BRANCH == "n" ]] && BRANCH="next-release"        
	fi

    echo ""
}

# =====================================
# -- clone_repository
# --
# -- $1 = BRANCH
# -- $2 = INSTALL_LOCATION
# -- $3 = INSTALL_PATH
# =====================================
function clone_repository () {
    local GIT_CMD="git"
    local BRANCH=$1
    local INSTALL_LOCATION=$2
    local INSTALL_PATH=$3
    
    # -- Check the install location and use sudo if needed
    _debug "INSTALL_LOCATION: $INSTALL_LOCATION INSTALL_PATH: $INSTALL_PATH BRANCH: $BRANCH"

    if [[ $INSTALL_LOCATION == "system" ]]; then        
        # -- Check if running as root
        echo -n "$(_loading "- Checking if running as root...")"
        if [[ $EUID -ne 0 ]]; then
            _warning "Not running as root, cloning repository into $INSTALL_PATH using sudo"
            GIT_CMD="sudo git"
        else
            _loading "Running as root, cloning repository into $INSTALL_PATH"
        fi        
    fi

    # -- Check if directory exists
    if [[ ! -d $INSTALL_PATH ]]; then
        # -- Clone repository using $BRANCH
        _running2 "Start Cloning repository into $1..."
        
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

# =====================================
# -- _setup_env
# =====================================
function _setup_env() {
    # -- Check if zshbop is installed
    ZSHBOP_DIR="$(_search_zshbop 1)"
    [[ $? -ne 0 ]] && _error "zshbop not found, exiting." && exit 1
    _loading2 "Checking if we can write to \$HOME/.zshrc"
    # -- Check if we can write to $HOME
    if [[ -w $HOME ]]; then
        _success "We can write to $HOME"
        # -- Check if .zshrc has zshbop.zsh in it
        if [[ -f $HOME/.zshrc ]]; then
            # Check if source line already exists
            if grep -q "zshbop.zsh" $HOME/.zshrc; then
                _success "zshbop.zsh already in .zshrc, skipping"
                return 0
            fi
        fi
        _running2 "Adding zshbop.zsh to .zshrc"
        # -- Add source line to .zshrc
        echo "source $ZSHBOP_DIR/zshbop.zsh" >> $HOME/.zshrc
        _success "Added zshbop.zsh to .zshrc"
        return 0        
    else
        _error "We can't write to $HOME"
        return 1
    fi
}

# =====================================
# -- setup_zshbop
# --
# -- $1 = branch
# -- $2 = install location
# =====================================
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
    if [[ -w $INSTALL_PATH ]]; then
        _success "We can write to $INSTALL_PATH"
    else
        _error "We can't write to $INSTALL_PATH"
        exit 1
    fi

    # -- Clone Repository
    _running2 "Clone zshbop to $INSTALL_PATH/zshbop"
    _loading "Cloning repository $BRANCH into $INSTALL_PATH/zshbop..."
    clone_repository "$BRANCH" "$INSTALL_LOCATION" "$INSTALL_PATH/zshbop"

    # -- Setup .zshrc
     _running2 "Setting up system based .zshrc..."
    
    # -- Check if we can write to $HOME
    _setup_env
    DOTZSH=$?

    echo ""
    _divider
    _success "Installation complete."
    echo "  zshbop is installed in $INSTALL_PATH/zshbop"
    _divider
    echo ""
    if [[ $DOTZSH == "0" ]]; then
        _success "ZSH added to .zshrc type zsh to start your shell"
    else
        if [[ $DOTZSH == "1" ]]; then
            _error "- There's already a .zshrc in-place."        
        elif [[ $DOTZSH == "2" ]]; then
            _error "- We can't write to $HOME/.zshrc, you will need to invoke zshbop some other way"
        fi
        echo ""
        echo -e "  You can add the following to your .zshrc file:\n"            
        echo -e "\tsource $INSTALL_PATH/zshbop/zshbop.zsh\n"
        echo -e "  or type the following:\n"
        echo -e "\techo \"source $INSTALL_PATH/zshbop/zshbop.zsh\" >> ~/.zshrc"        
    fi
    echo ""    
    
    _divider
}

# =====================================--------------------------------------------------
# -- Main
# =====================================--------------------------------------------------

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

# =====================================
# -- help
# =====================================
if [[ $HELP == "1" ]];then
    usage
    exit
# -- clean
# =====================================
# -- clean
# =====================================
elif [[ $CMD == "clean" ]]; then
	_running "Running zshbop clean"
    _clean_zshbop
# ======================================
# -- search
# ======================================
elif [[ $CMD == "search" ]]; then
    _running "Running zshbop search"
    _search_zshbop
# =====================================
# -- default
# =====================================
elif [[ $CMD == "default" ]]; then
	pre_flight_check	
    BRANCH=main
    INSTALL_LOCATION=system
    setup_zshbop $BRANCH $INSTALL_LOCATION 
# =====================================
# -- home
# =====================================
elif [[ $CMD == "home" ]]; then
	pre_flight_check    
    BRANCH=main
    INSTALL_LOCATION=home
    setup_zshbop $BRANCH $INSTALL_LOCATION 
# =====================================
# -- git
# =====================================
elif [[ $CMD == "git" ]]; then
	pre_flight_check	
	BRANCH=dev
	INSTALL_LOCATION=git
    setup_zshbop $BRANCH $INSTALL_LOCATION 
# =====================================
# -- custom
# =====================================
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
# =====================================
# -- env
# =====================================
elif [[ $CMD == "env" ]]; then
    # Setup environment variables in .zshrc
    _running "Setting up environment variables in .zshrc"
    _setup_env
# =====================================
# -- install
# =====================================
else
    if [[ -n $CMD ]]; then
        usage
        exit 1
    fi
    pre_flight_check
	install_method
    setup_zshbop $BRANCH $INSTALL_LOCATION 
fi
