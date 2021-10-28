# --------------
# -- Init
# --------------
# This is the initilization for jtzsh

# Use colors, but only if connected to a terminal
# and that terminal supports them.

# ------------
# -- Variables
# ------------
export UNAME=$(uname -s)
case "${UNAME}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Cygwin;;
    MINGW*)     MACHINE=MinGw;;
    *)          MACHINE="UNKNOWN:${unameOut}"
esac
echo "- Running in ${MACHINE}"

# Colors
autoload colors
if [[ "$terminfo[colors]" -gt 8 ]]; then
    colors
fi
for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
    eval $COLOR='$fg_no_bold[${(L)COLOR}]'
    eval BOLD_$COLOR='$fg_bold[${(L)COLOR}]'
done
eval RESET='$reset_color'
eval BGRED='$bg[red]'
eval BGGREEN='$bg[green]'

local -a RAINBOW
local RED GREEN YELLOW BLUE BOLD DIM UNDER RESET

if [ -t 1 ]; then
  RAINBOW=(
    "$(printf '\033[38;5;196m')"
    "$(printf '\033[38;5;202m')"
    "$(printf '\033[38;5;226m')"
    "$(printf '\033[38;5;082m')"
    "$(printf '\033[38;5;021m')"
    "$(printf '\033[38;5;093m')"
    "$(printf '\033[38;5;163m')"
  )

  RED=$(printf '\033[31m')
  GREEN=$(printf '\033[32m')
  YELLOW=$(printf '\033[33m')
  BLUE=$(printf '\033[34m')
  BOLD=$(printf '\033[1m')
  DIM=$(printf '\033[2m')
  UNDER=$(printf '\033[4m')
  RESET=$(printf '\033[m')
fi

# Default tools to install
default_tools=('mosh' 'traceroute' 'mtr' 'pwgen' 'tree' 'ncdu' 'fpart' 'whois' 'pwgen' 'python3-pip' 'joe' 'keychain')
extra_tools=('pip')

# -----------------------
# -- One line functions
# -----------------------

# -- Init
init () {
        #- Include functions file
        _echo "-- Starting init"
        source $ZSH_ROOT/functions.zshrc # Core functions
        source $ZSH_ROOT/functions-tools.zshrc # Fucntions that are tools.
        source $ZSH_ROOT/aliases.zsh
        init_path
        init_omz_plugins
        init_antigen
        init_defaults
        init_sshkeys
        if [[ $ENABLE_ULTB == 1 ]]; then init_ultb; fi
        if [[ $ENABLE_UWT == 1 ]]; then init_uwt; fi
        neofetch
        startup_motd
}

# -- PATHS!
init_path () {
	# Default paths to look for
        export PATH=$PATH:$HOME/bin:/usr/local/bin:$ZSH_ROOT:$ZSH_ROOT/bin
        export PATH=$PATH:$HOME/.local/bin
        
        # Extra software
        export PATH=$PATH:$ZSH_ROOT/bin/cloudflare-cli # https://github.com/bAndie91/cloudflare-cli
	export PATH=$PATH:$ZSH_ROOT/bin/clustergit # https://github.com/mnagel/clustergit
	export PATH=$PATH:$ZSH_ROOT/bin/MySQLTuner-perl # https://github.com/major/MySQLTuner-perl
	export PATH=$PATH:$ZSH_ROOT/bin/parsyncfp # https://github.com/hjmangalam/parsyncfp
	export PATH=$PATH:$ZSH_ROOT/bin/httpstat # https://github.com/reorx/httpstat

	# Functions
	source $ZSH_ROOT/bin/functions.zsh

	# -- Mention some tools need to be installed.
	if (( !$+commands[ls] )); then
	        echo "pip doesn't exist?"
	else
	        echo "pip not installed, run ultb-install"
	fi
}

# -- Initialize oh-my-zsh plugins
init_omz_plugins () {
	_echo "-- Loading OMZ plugins"
	plugins=( git z )
	_echo " - $plugins"
}

# -- Initialize Antigen
init_antigen () {
	_echo "-- Loading Antigen"
        if [[ -a $ZSH_ROOT/antigen.zsh ]]; then
                _debug "- Loading antigen from $ZSH_ROOT/antigen.zsh";
		source $ZSH_ROOT/antigen.zsh
		antigen init $ZSH_ROOT/.antigenrc
        else
                _echo "	- Couldn't load antigen..";
        fi
}

# -- Load default zsh scripts
init_defaults () {
        _echo "-- Loading default scripts"
        source $ZSH_ROOT/defaults.zshrc

        # Find out if we have personal ZSH scripts.
        printf "-- Loading personal ZSH scripts...\n"
        if [[ -a $ZSH_ROOT/zsh-personal/.zshrc || -L $ZSH_ROOT/zsh-personal/.zshrc ]]; then
                ZSH_PERSONAL_DIR=$ZSH_ROOT/zsh-personal
        elif [[ -a $HOME/git/zsh-personal/.zshrc || -L $HOME/git/zsh-personal/.zshrc ]]; then
                ZSH_PERSONAL_DIR=$HOME/git/zsh-personal
        elif [[ -a $HOME/.personal.zshrc || -L $HOME/.personal.zshrc ]]; then
                ZSH_PERSONAL_SCRIPT=$HOME/.personal.zshrc
        fi

        # Source personal configuration
        if [ ! -z $ZSH_PERSONAL_DIR ]; then
                echo " - Loading $ZSH_PERSONAL_DIR/.zshrc"
                source $ZSH_PERSONAL_DIR/.zshrc
        elif [ ! -z $ZSH_PERSONAL_SCRIPT]; then
                echo " - Loading $ZSH_PERSONAL_SCRIPT"
                source $ZSH_PERSONAL_SCRIPT
        else
                printf " - No personal ZSH config loaded\n"
        fi
}

# -- Load default SSH keys into keychain
init_sshkeys () {
	_echo "-- Loading SSH keychain"
	if (( $+commands[keychain] )); then
	        # Load default SSH key
	        _debug " - Check for default SSH key $HOME/.ssh/id_rsa and load keychain"
        	if [[ -a $HOME/.ssh/id_rsa || -L $HOME/.ssh/id_rsa ]]; then
	                _debug  " - FOUND: $HOME/.ssh/id_rsa"
	                eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa`
	        else
	                _debug " - NOTFOUND: $HOME/.ssh/id_rsa"
        	fi

	        # Check and load custom SSH key
        	_debug " - Check for custom SSH key via $SSH_KEY and load keychain"
	        if [ ! -z "${SSH_KEY+1}" ]; then
        	        _debug " - FOUND: $SSH_KEY"
                	eval `keychain -q --eval --agents ssh $SSH_KEY`
	        else
        	        _debug " - NOTFOUND: $SSH_KEY not set."
	        fi

		# Load any id_rsa* keys
		if [[ $ENABLE_ALL_SSH_KEYS == 1 ]]; then
			eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa*`
		fi
	else
		_echo " - Command keychain doesn't exist, please install for SSH keys to work"
	fi
}

# -- Ultimate WordPress Tools
init_uwt () {
        if [[ -a $ZSH_ROOT/ultimate-wordpress-tools/.zshrc ]]; then
                _echo "-- Including Ultimate WordPress Tools"
                source $ZSH_ROOT/ultimate-wordpress-tools/.zshrc
	fi
	export PATH=$PATH:$ZSH_ROOT/ultimate-wordpress-tools
}

