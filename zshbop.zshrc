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
ZSHBOP_COMMIT=$(git -C $ZSHBOP_ROOT rev-parse HEAD)
ZSHBOP_REPO="jordantrizz/zshbop"

# -- Current version installed
ZSHBOP_VERSION=$(<$ZSHBOP_ROOT/version)

# -- Set help_zshbop
typeset -gA help_zshbop

# -- Set help_custom for custom help files
typeset -gA help_custom

# -- Previous zsbop paths
ZSHBOP_MIGRATE_PATHS=("/usr/local/sbin/zsh" "$HOME/zsh" "$HOME/git/zsh")

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
		echo "$fg[cyan]** DEBUG: $@$reset_color"; 
	fi
}

#-- Check to see if command exists and then return true or false
_cexists () {
        if (( $+commands[$@] )); then
        	_debug $(which $1)
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

_checkroot () {
	if [[ $EUID -ne 0 ]]; then
		_error "Requires root...exiting." 
	return
	fi
}

_debug_all () {
        _debug "--------------------------"
        _debug "arguments - $@"
        _debug "funcstack - $funcstack"
        _debug "ZSH_ARGZERO - $ZSH_ARGZERO"
        _debug "--------------------------"
}

_if_marray () {
        valid=1
        _debug "$funcstack[1] - find value = $1 in array = $2"
        for value in ${(k)${(P)2[@]}}; do
                _debug "$funcstack[2] - array=$2 \$value = $value"
                if [[ $value == "$1" ]]; then
                        _debug "$funcstack[1] - array $2 does contain $1"
                        valid="0"
                else
                        _debug "$funcstack[1] - array $2 doesn't contain $1"
                fi
        done
        _debug "valid = $valid"
        if [[ valid == "1" ]]; return 0
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
	source $HOME/.zshrc
	_warning "You may have to close your shell and restart it to see changes"
}

# -- zshbop_startup
help_zshbop[startup]='Run zshbop startup'
zshbop_startup () { startup_motd; }

# -- check-migrate
help_zshbop[check-migrate]='Check if running old zshbop.'
zshbop_check-migrate () {
        echo " -- Checking for legacy zshbop"
        FOUND="0"
        for ZBPATH_MIGRATE in "${ZSHBOP_MIGRATE_PATHS[@]}"; do
                if [ -d "$ZBPATH_MIGRATE" ]; then
                        _error "Detected old zshbop under $ZBPATH_MIGRATE, run 'zshbop migrate'";
                        FOUND="1"
                fi
        done
        if [[ "$FOUND" == "0" ]]; then
                echo " -- Don't need to migrate legacy zshbop"
        fi
}

# -- migrate
help_zshbop[migrate]='Migrate old zshbop to new zshbop'
zshbop_migrate () {
        echo " -- Migrating legacy zshbop"
        FOUND="0"
        for ZBPATH_MIGRATE in "${ZSHBOP_MIGRATE_PATHS[@]}"; do
                if [ -d "$ZBPATH_MIGRATE" ]; then
                        echo " -- Moving $ZBPATH_MIGRATE to ${ZBPATH_MIGRATE}bop"
                        sudo mv $ZBPATH_MIGRATE ${ZBPATH_MIGRATE}bop
                        echo " -- Copying ${ZBPATH_MIGRATE}bop/.zshrc to your $HOME/.zshrc"
                        cp ${ZBPATH_MIGRATE}bop/.zshrc $HOME/.zshrc
                        FOUND="1"
                fi
        done
        if [[ "$FOUND" == "0" ]]; then
                echo " -- Don't need to migrate legacy zshbop"
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
        CURRENT_ZSHRC_MD5=$(md5sum $HOME/.zshrc | awk {' print $1 '})
        ZSHBOP_ZSHRC_MD5="47a679861c437bceaa481d83ccaa6c10"
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

# -- Init
init