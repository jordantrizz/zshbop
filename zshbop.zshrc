# ------------------------
# -- zshbop functions file
# -------------------------
# This file contains all the required functions for the main .zshrc script.

# ------------
# -- Variables
# ------------

# -- Current zshbop branch
SCRIPT_NAME="zshbop"
ZSH_ROOT=$ZSHBOP_ROOT # Converting from ZSH_ROOT to ZSHBOP_ROOT
ZSHBOP_BRANCH=$(git -C $ZSHBOP_ROOT rev-parse --abbrev-ref HEAD)
ZSHBOP_COMMIT=$(git rev-parse HEAD)
ZSHBOP_REPO="jordantrizz/zshbop"

# -- Current version installed
ZSHBOP_VERSION=$(<$ZSHBOP_ROOT/version)

# -- Set help_zshbop
typeset -gA help_zshbop

# -----------
# -- includes
# -----------
source $ZSHBOP_ROOT/init.zshrc

# -----------------------
# -- Internal Functions
# -----------------------

# -- Different colored messages
_echo () { echo "$@" }
_error () { echo  "$fg[red] ** $@ $reset_color" }
_warning () { echo "$fg[yellow] ** $@ $reset_color" }
_success () { echo "$fg[green] ** $@ $reset_color" }
_notice () { echo "$fg[blue] ** $@ $reset_color" }

# -- debugging
_debug () { 
	if [[ $ZSH_DEBUG == 1 ]]; then 
		echo "** DEBUG: $@"; 
	fi
}

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
alias zb=zshbop
zshbop () {
	if [[ $1 == "help" ]] || [[ ! $1 ]]; then
		echo " --- zshbop help $fg[green]$ZSHBOP_VERSION/$ZSHBOP_BRANCH$reset_color ---"
		echo ""
	        for key value in ${(kv)help_zshbop}; do
        	        printf '%s\n' "  ${(r:25:)key} - $value"
	        done
	        echo ""
	else
		echo "-- Running zshbop $1"
		zshbop_cmd=(zshbop_${1})
		$zshbop_cmd $@
	fi
}

# -- rld / reload
help_zshbop[reload]='Reload zshbop'
alias rld=zshbop_reload
zshbop_reload () { 
	source $ZSHBOP_ROOT/init.zshrc;init 
	_warning "You may have to close your shell and restart it to see changes"
}

# -- zshbop_startup
help_zshbop[startup]='Run zshbop startup'
zshbop_startup () { startup_motd; }

# -- check-migrate
help_zshbop[check-migrate]='Check if running old zshbop.'
zshbop_check-migrate () {
	echo " -- Checking for legacy zshbop"
        if [ -d /usr/local/sbin/zsh ]; then _error "Detected old zshbop under /usr/local/sbin/zsh, double check and run zshbop_migrate";
        elif [ -d $HOME/zsh ];then _error "Detected old zshbop under $HOME/zsh, double check and run zshbop_migrate";
        elif [ -d $HOME/git/zsh ];then _error "Detected old zshbop under $HOME/git/zsh, double check and run zshbop_migrate";
        else
        	echo " -- Not running legacy zshbop"
        fi        
}

# -- migrate
help_zshbop[migrate]='Migrate old zshbop to new zshbop'
zshbop_migrate () {
        if [ -d /usr/local/sbin/zsh ]; then
                echo "-- Moving /usr/local/sbin/zsh to /usr/local/sbin/zshbop"
                sudo mv /usr/local/sbin/zsh /usr/local/sbin/zshbop
                echo "-- Copying /usr/local/sbin/zshbop/.zshrc_install to your $HOME/.zshrc"
                cp /usr/local/sbin/zshbop/.zshrc_install $HOME/.zshrc
        fi
        if [ -d $HOME/zsh ]; then
                echo "-- Moving $HOME/zsh to $HOME/zshbop"
                mv $HOME/zsh $HOME/zshbop
                echo "-- Copying $HOME/zshbop/.zshrc_install to your $HOME/.zshrc"
                cp $HOME/zshbop/.zshrc_install $HOME/.zshrc
        fi
        if [ -d $HOME/git/zsh ]; then
                echo "-- Moving $HOME/git/zsh to $HOME/git/zshbop"
                mv $HOME/git/zsh $HOME/git/zshbop
		echo "-- Copyiong $HOME/zshbop/.zshrc_install to $HOME/.zshrc"
                cp $HOME/zshbop/.zshrc_install $HOME/.zshrc
        fi
}

# -- branch
help_zshbop[branch]='Run master or development branch of zshbop'
zshbop_branch  () {
        if [ "$2" = "develop" ]; then
                echo "	-- Switching to develop branch"
                git -C $ZSHBOP_ROOT checkout develop
        elif [ "$2" = "master" ]; then
                echo "	-- Switching to master branch"
                git -C $ZSHBOP_ROOT checkout master
        elif [ -z $2 ]; then
                echo "	-- zshbop: $ZSHBOP_ROOT branch: $ZSHBOP_BRANCH ----"
                echo "	-- To switch branch type zshbop branch develop or zshbop branch master"
        else
        	_error "Unknown $@"
        fi
}

# -- check-updates - Check for zshbop updates.
help_zshbop[check-updates]='Check for zshbop update, not completed yet'
zshbop_check-updates () {
	# Sources for version check
	MASTER_UPDATE="https://raw.githubusercontent.com/$ZSHBOP_REPO/master/version"
	DEVELOP_UPDATE="https://raw.githubusercontent.com/$ZSHBOP_REPO/develop/version"

        _debug "	-- Running $ZSHBOP_VERSION, checking $ZSHBOP_BRANCH for updates."
        if [[ "$ZSHBOP_BRANCH" = "master" ]]; then
        	_debug "	-- Checking $MASTER_UPDATE on $ZSHBOP_REPO"
        	NEW_MASTER_VERSION=$(curl -s $DEVELOP_UPDATE)
        	if [[ $NEW_MASTER_VERSION != $ZSHBOP_VERSION ]]; then
        		_warning "Update available $NEW_MASTER_VERSION"
                else
                        _success "Running current version $NEW_MASTER_VERSION"
                fi
        elif [[ "$ZSHBOP_BRANCH" = "develop" ]]; then
		# Get repository develop commit.
        	ZSHBOP_REMOTE_COMMIT=$(curl -s https://api.github.com/repos/jordantrizz/zshbop/branches/develop | jq -r '.commit.sha')

		# Check remote github.com repository
        	_debug "	-- Checking $DEVELOP_UPDATE on $ZSHBOP_REPO"
        	NEW_DEVELOP_VERSION=$(curl -s $DEVELOP_UPDATE)
	
        	# Compare versions	
        	if [[ $NEW_DEVELOP_VERSION != $ZSHBOP_VERSION ]]; then
	        	_warning "Update available $NEW_DEVELOP_VERSION"
	        else
	        	_success "Running current version $NEW_DEVELOP_VERSION"
	        fi
	        
	        # Compare commits
	        _debug "	-- Checking $ZSHBOP_COMMIT against $ZSHBOP_REMOTE_COMMIT"
	        if [[ $ZSHBOP_COMMIT != $ZSHBOP_REMOTE_COMMIT ]]; then
	        	_warning "Not on $ZSHBOP_BRANCH latest commit - Local: $ZSHBOP_COMMIT / Remote: $ZSBBOP_REMOTE_COMMIT"
	        fi
        	
        else
        	_error "Don't know what branch zshbop is on"
        fi
}

# -- update - Update ZSHBOP
help_zshbop[update]='Update zshbop'
zshbop_update () {
        # Pull zshbop
        echo "-- Pulling zshbop updates"
        git -C $ZSHBOP_ROOT pull

        # Update Personal ZSH
        if [ ! -z $ZSH_PERSONAL_DIR ]; then
                echo "-- Pulling Personal ZSH repo"
                git -C $ZSH_PERSONAL_DIR pull
        fi

        # Update repos
        for name in $ZSHBOP_ROOT/repos/*
        do
                echo "-- Updating repo $name"
                git -C $name pull
        done

        # Reload scripts
        _warning "Type zb reload to reload zshbop, or restart your shell."
}

help_zshbop[previous-version-check]='Checking if \$HOME/.zshrc is pre v1.1.3 and replacing.'
zshbop_previous-version-check () {
        # Replacing .zshrc previous to v1.1.2 256bb9511533e9697f639821ba63adb9
        echo " -- Checking if $HOME/.zshrc is pre v1.1.3"
        CURRENT_ZSHRC_MD5=$(md5sum $HOME/.zshrc)
        ZSHBOP_ZSHRC_MD5="bc6c62965dfe93767c3bb9fabed48ce6"
        _debug " -- Current .zshrc md5 is - $CURRENT_ZSHRC_MD5"
        _debug " -- zshbop .zshrc md5 is - $ZSHBOP_ZSHRC_MD5"
        if [[ "$CURRENT_ZSHRC_MD5" != "$ZSHBOP_ZSHRC_MD5" ]]; then
                echo " -- Replacing $HOME/.zshrc due to v1.1.3 changes."
                cp $ZSHBOP_ROOT/.zshrc $HOME/.zshrc
        else
        	echo " -- No need to fix .zshrc"
        fi
}

# -- zshbop_color
help_zshbop[colors]='List variables for using color'
zshbop_colors () {
	for k in ${color}; do
	   print -- key: $k 
	done
}

# -- Check if $HOME/.zshrc needs to be replaced and do it fingers crossed.
zshbop_previous-version-check

# -- Initalize and Start ZSHBOP
init
