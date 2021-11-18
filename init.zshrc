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

zmodload zsh/mapfile
export HISTSIZE=5000
export PAGER='less -Q -j16'
export EDITOR='joe'
export BLOCKSIZE='K'
export bgnotify_threshold='6' # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/bgnotify
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

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

# ------------------
# -- fzf keybindings
# ------------------
# Need to enable if fzf is available
#[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"
####-- diff-so-fancy
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"

# Default tools to install
default_tools=('mosh' 'traceroute' 'mtr' 'pwgen' 'tree' 'ncdu' 'fpart' 'whois' 'pwgen' 'python3-pip' 'joe' 'keychain')
extra_tools=('pip' 'npm')
pip_install=('ngxtop' 'apt-select')

# -----------------------
# -- One line functions
# -----------------------

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
		source $ZSH_ROOT/antigen.zsh > /dev/null 2>&1
		antigen init $ZSH_ROOT/.antigenrc > /dev/null 2>&1
        else
                _echo "	- Couldn't load antigen..";
        fi
}

# -- Load default zsh scripts
init_defaults () {
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
        
	# Include OS Specific configuration
	if [[ $MACHINE == "Mac" ]] then
        	echo "- Loading os/mac.zshrc"
	        source $ZSH_ROOT/os/mac.zshrc
	elif [[ $MACHINE = "Linux" ]] then
        	if [[ $(uname -r) =~ "Microsoft" || $(uname -r) =~ "microsoft" ]] then
                	echo "- Loading os/wsl.zshrc"
	                source $ZSH_ROOT/os/wsl.zshrc
	        else
	                source $ZSH_ROOT/os/linux.zshrc
        	        echo "- Loading os/linux.zshrc"
	        fi
	fi

	# Include task specific files.
	echo " -- Loading WordPress commands"
	source $ZSH_ROOT/wordpress.zshrc

	# --- Include custom configuration
	if [ -f $HOME/.zshbop ]; then
        	echo " -- Loading custom configuration"
	        source $HOME/.zshbop
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
		# Load any client-* keys
		if [[ $ENABLE_ALL_SSH_KEYS == 1 ]]; then
                        eval `keychain -q --eval --agents ssh $HOME/.ssh/clients*`
                fi
	else
		_echo " - Command keychain doesn't exist, please install for SSH keys to work"
	fi
}

zshbop_check_migrate () {
	if [ -d /usr/local/sbin/zsh ]; then echo "$RED---- Detected old zshbop under /usr/local/sbin/zsh, double check and run zshbop_migrate ----$RESET"; fi
	if [ -d $HOME/zsh ];then  echo "$RED---- Detected old zshbop under $HOME/zsh, double check and run zshbop_migrate ----$RESET"; fi
	if [ -d $HOME/git/zsh ];then echo "$RED---- Detected old zshbop under $HOME/git/zsh, double check and run zshbop_migrate ----$RESET"; fi
}

zshbop_migrate () {
	if [ -d /usr/local/sbin/zsh ]; then
		echo "---- Moving /usr/local/sbin/zsh to /usr/local/sbin/zshbop"
		sudo mv /usr/local/sbin/zsh /usr/local/sbin/zshbop
		echo "---- Make sure to copy /usr/local/sbin/zshbop/.zshrc_install to your .zshrc locations"	
	fi
	if [ -d $HOME/zsh ]; then
		echo "---- Moving $HOME/zsh to $HOME/zshbop"
		mv $HOME/zsh $HOME/zshbop
		echo "---- Make sure to copy $HOME/zshbop/.zshrc_install to your .zshrc"
	fi
	if [ -d $HOME/git/zsh ]; then
		echo "---- Moving $HOME/git/zsh to $HOME/git/zshbop"
		mv $HOME/git/zsh $HOME/git/zshbop
		echo "---- Make sure to copy $HOME/zshbop/.zshrc_install to your .zshrc"
	fi	
}

zshbop  () {
	if [ -z $1 ]; then
		echo "---- ZSH_ROOT = $ZSH_ROOT"
	        BRANCH=$(git -C $ZSH_ROOT rev-parse --abbrev-ref HEAD)
	        echo "---- Running zshbop $BRANCH ----"
		echo "---- To switch branch type zshbop develop or zshbop master"
	elif [ "$1" = "develop" ]; then
		echo "---- Switching to develop branch"
		git -C $ZSH_ROOT checkout develop
	elif [ "$1" = "master" ]; then
		echo "---- Switching to master branch"
		git -C $ZSH_ROOT checkout master
	fi
}

zshbop_switch_branch () {

}

# -- Init
init () {
        #- Include functions file
        _echo "-- Starting init"
        init_path
        source $ZSH_ROOT/functions.zshrc # Core functions
        source $ZSH_ROOT/functions-tools.zshrc # Fucntions that are tools.
        source $ZSH_ROOT/aliases.zsh
        init_omz_plugins
        init_antigen
        init_defaults
        init_sshkeys       
}

startup_motd () {
        neofetch
        zshbop
        zshbop_check_migrate
        echo "-- Screen Sessions --"
        screen -list
        echo "---- Run checkenv to make sure you have all the right tools! ----"
}
