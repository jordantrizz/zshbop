# --------------
# -- Functions
# --------------
# This file contains all the required functions for the main .zshrc script.

# Set help_zshbop
typeset -gA help_zshbop

# -----------------------
# -- Internal Functions
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

# -------------------
# -- zshbop functions
# -------------------

# -- zshbop
zshbop () {
	if [[ $1 == "help" ]] || [[ ! $1 ]]; then
		echo " --- zshbop help ---"
		echo ""
	        for key value in ${(kv)help_zshbop}; do
        	        printf '%s\n' "  ${(r:25:)key} - $value"
	        done
	        echo ""
	else
		echo "-- Running zshbop $1"
		zshbop_cmd=(zshbop_${1})
		$zshbop_cmd
	fi
}

# -- rld / reload
help_zshbop[reload]='Reload zshbop'
alias rld=zshbop_reload
zshbop_reload () { 
	source $ZSH_ROOT/init.zshrc;init 
}

# -- check-migrate
help_zshbop[check-migrate]='Check if running old zshbop.'
zshbop_check-migrate () {
	echo " -- Checking for legacy zshbop"
        if [ -d /usr/local/sbin/zsh ]; then echo "$RED---- Detected old zshbop under /usr/local/sbin/zsh, double check and run zshbop_migrate ----$RESET";
        elif [ -d $HOME/zsh ];then  echo "$RED---- Detected old zshbop under $HOME/zsh, double check and run zshbop_migrate ----$RESET";
        elif [ -d $HOME/git/zsh ];then echo "$RED---- Detected old zshbop under $HOME/git/zsh, double check and run zshbop_migrate ----$RESET";
        else
        	echo " -- Not running legacy zshbop"
        fi        
}

# -- migrate
help_zshbop[migrate]='Migrate old zshbop to new zshbop'
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

# -- branch
help_zshbop[branch]='Run master or development branch of zshbop'
zshbop_branch  () {
        if [ -z $1 ]; then
                echo "---- ZSH_ROOT = $ZSH_ROOT"
                BRANCH=$(git -C $ZSH_ROOT rev-parse --abbrev-ref HEAD)
                echo "---- Running zshbop $BRANCH ----"
                echo "---- To switch branch type zshbop branch develop or zshbop branch master"
        elif [ "$2" = "develop" ]; then
                echo "---- Switching to develop branch"
                git -C $ZSH_ROOT checkout develop
        elif [ "$2" = "master" ]; then
                echo "---- Switching to master branch"
                git -C $ZSH_ROOT checkout master
        fi
}

# -- check-updates - Check for zshbop updates.
help_zshbop[check-updates]='Check for zshbop update, not completed yet'
zshbop_check-updates () {
        echo " -- Not completed yet"
}

# -- update - Update ZSHBOP
help_zshbop[update]='Update zshbop'
zshbop_update () {
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