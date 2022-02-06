# --------------
# -- Functions
# --------------
# This file contains all the required functions for the main .zshrc script.

# -----------------------
# -- One line functions
# -----------------------

# -- placehodler for echo
_echo () { echo "$@" }

# -- debugging
_debug () { if [[ $ZSH_DEBUG == 1 ]]; then echo "** DEBUG: $@"; fi }

#-- Check to see if command exists and then return true or false
_cexists () {
        if (( $+commands[$@] )); then
                if [[ $ZSH_DEBUG == 1 ]]; then
                        _debug "$@ is installed";
                fi
                return 0
        else
                if [[ $ZSH_DEBUG == 1 ]]; then
                        _debug "$@ not installed";
                fi
                return 1
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
	echo "Needs to be removed"
}

# -- check-updates - Check for zshbop updates.
help_core[check-updates]='Check for zshbop update, not completed yet'
check-updates () {
        echo " -- Not completed yet"
}

# -- update - Update ZSHBOP
help_core[update]='Update zshbop'
update () {
        # Pull zshbop
        echo "--- Pulling zshbop updates"
        git -C $ZSH_ROOT pull

        # Update Personal ZSH
        if [ ! -z $ZSH_PERSONAL_DIR ]; then
                echo "--- Pulling Personal ZSH repo"
                git -C $ZSH_PERSONAL_DIR pull
        fi

        # Update repos
        for name in $ZSH_ROOT/repos/*
        do
                echo "-- Updating repo $name"
                git -C $name pull
        done

        # Reload scripts
        echo "--- Type rld to reload zshbop"
}