#!/usr/bin/env zsh
# ------------------------
# -- zshbop functions file
# -------------------------
# This file contains all the required functions for the main .zshrc script.

_debug "Loading mypath=${0:a}"

# -----------
# -- ZSH Aliases
# -----------
alias update="zshbop_update"
alias rld="zshbop_reload"
alias zb=zshbop

# ---------------------
# -- Internal Functions
# ---------------------

#-- Check to see if command exists and then return true or false
_cexists () {
        if (( $+commands[$@] )); then
        	_debug $(which $1)
                if [[ $ZSH_DEBUG == 1 ]]; then
                        _debug "$@ is installed";
                fi
                CMD_EXISTS="0"
        else
                if [[ $ZSH_DEBUG == 1 ]]; then
                        _debug "$@ not installed";
                fi
                CMD_EXISTS="1"
        fi
        return $CMD_EXISTS
}

_checkroot () {
        _debug_function
	if [[ $EUID -ne 0 ]]; then
		_error "Requires root...exiting."
	return
	fi
}

_if_marray () {
	_debug_function
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

# -- _joe_ftyperc - setting up .joe folder
_joe_ftyperc () {
	_debug_function
        _debug "Checking for ~/.joe folder"
	[[ ! -d ~/.joe ]] && mkdir ~/.joe
	_debug "Checking for joe ftyperc"
        if [[ ! -f ~/.joe/ftyperc ]]; then
                _debug "Missing ~/.joe/ftyperc, copying"
                cp $ZSHBOP_ROOT/custom/ftyperc ~/.joe/ftyperc
        fi
}

# -------------------
# -- zshbop functions
# -------------------

# -- help_zshbop array
typeset -gA help_zshbop # -- Set help_zshbop

# -- rld / reload
help_zshbop[reload]='Reload zshbop'
zshbop_reload () {
        _debug_function
	source $HOME/.zshrc
	_warning "You may have to close your shell and restart it to see changes"
        echo ""
}

# -- zshbop_startup
help_zshbop[startup]='Run zshbop startup'
zshbop_startup () {
	_debug_function
	startup_motd
}

# -- migrate
help_zshbop[migrate]='Migrate old zshbop to new zshbop'
zshbop_migrate () {
	_debug_function
        echo " -- Check Migrating legacy zshbop"
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
help_zshbop[branch]='Run main or dev branch of zshbop'
zshbop_branch  () {
        _debug_function
        if [ "$2" = "dev" ]; then
                echo "	-- Switching to dev branch"
                git -C $ZSHBOP_ROOT checkout dev
        elif [ "$2" = "main" ]; then
                echo "	-- Switching to main branch"
                git -C $ZSHBOP_ROOT checkout main
        elif [ -z $2 ]; then
                echo "	-- zshbop: $ZSHBOP_ROOT branch: $ZSHBOP_BRANCH ----"
                echo "	-- To switch branch type 'zshbop branch dev' or 'zshbop branch main'"
        else
        	_error "Unknown $@"
        fi
}

# -- check-updates - Check for zshbop updates.
help_zshbop[check-updates]='Check for zshbop update, not completed yet'
zshbop_check-updates () {
        _debug_function

        # Sources for version check
	MAIN_UPDATE="https://raw.githubusercontent.com/$ZSHBOP_REPO/main/version"
	DEV_UPDATE="https://raw.githubusercontent.com/$ZSHBOP_REPO/dev/version"

        _notice "-- Running $ZSHBOP_VERSION/$ZSHBOP_BRANCH/$ZSHBOP_COMMIT checking $ZSHBOP_BRANCH for updates."
        if [[ "$ZSHBOP_BRANCH" = "main" ]]; then
        	echo "-- Checking version on $MAIN_UPDATE"
        	NEW_MAIN_VERSION=$(curl -s $MAIN_UPDATE)
        	if [[ $NEW_MAIN_VERSION != $ZSHBOP_VERSION ]]; then
        		_warning "Update available $NEW_MAIN_VERSION"

                else
                        _success "Running current version $NEW_MAIN_VERSION"
                fi
        elif [[ "$ZSHBOP_BRANCH" = "dev" ]]; then
		# Get repository dev commit.
        	ZSHBOP_REMOTE_COMMIT=$(curl -s https://api.github.com/repos/jordantrizz/zshbop/branches/dev | jq -r '.commit.sha')

		# Check remote github.com repository
        	echo "-- Checking version on $DEV_UPDATE"
        	NEW_DEV_VERSION=$(curl -s $DEV_UPDATE)

                # Compare versions
        	if [[ $NEW_DEV_VERSION != $ZSHBOP_VERSION ]]; then
	        	_warning "Update available $NEW_DEV_VERSION"
	        else
	        	_success "Running current version $NEW_DEV_VERSION"
	        fi

	        # Compare commits
	        echo "-- Checking commit on branch $ZSHBOP_BRANCH "
                if [[ $ZSHBOP_COMMIT != $ZSHBOP_REMOTE_COMMIT ]]; then
	        	_warning "Not on $ZSHBOP_BRANCH latest commit - Local: $ZSHBOP_COMMIT / Remote: $ZSHBOP_REMOTE_COMMIT"
	        else
                        _success "On $ZSHBOP_BRANCH latest commit - Local: $ZSHBOP_COMMIT / Remote: $ZSHBOP_REMOTE_COMMIT"
                fi

        else
        	_error "Don't know what branch zshbop is on"
        fi
}

# -- update - Update ZSHBOP
help_zshbop[update]='Update zshbop'
zshbop_update () {
	_debug_function
        zshbop_version
        # Pull zshbop
        echo "-- Pulling zshbop updates"
        git -C $ZSHBOP_ROOT pull

	# Check if .zshrc is out of date.
	# Called from script directly versus cached functions
	$ZSHBOP_ROOT/zshbop.zsh previous-version-check

        # Update Personal ZSH
        if [ ! -z $ZSH_PERSONAL_DIR ]; then
                echo "-- Pulling Personal ZSH repo"
                git -C $ZSH_PERSONAL_DIR pull
        fi

        # Update repos
	repos update

        # Reload scripts
        _warning "Type zb reload to reload zshbop, or restart your shell."
}

# -- zshbop_pervious-version-check
help_zshbop[previous-version-check]='Checking if \$HOME/.zshrc is pre v1.1.3 and replacing.'
zshbop_previous-version-check () {
        _debug_function

        # Replacing .zshrc previous to v1.1.2 256bb9511533e9697f639821ba63adb9
        _debug " -- Checking if $HOME/.zshrc is pre v1.1.3"
        CURRENT_ZSHRC_MD5=$(md5sum $HOME/.zshrc | awk {' print $1 '})
        _debug " -- Current $HOME/.zshrc md5 is - $CURRENT_ZSHRC_MD5"
        _debug " -- zshbop .zshrc md5 is - $ZSHBOP_ZSHRC_MD5"
        if [[ "$CURRENT_ZSHRC_MD5" != "$ZSHBOP_ZSHRC_MD5" ]]; then
                echo "-- Found old .zshrc"
                echo "-- Replacing $HOME/.zshrc"
                cp $ZSHBOP_ROOT/.zshrc $HOME/.zshrc
        else
        	_debug " -- No need to fix .zshrc"
        fi
}

# -- check-migrate
help_zshbop[check-migrate]='Check if running old zshbop.'
zshbop_check-migrate () {
	_debug_function
        _debug " -- Checking for legacy zshbop"
        FOUND="0"
        for ZBPATH_MIGRATE in "${ZSHBOP_MIGRATE_PATHS[@]}"; do
                if [ -d "$ZBPATH_MIGRATE" ]; then
                        _error "Detected old zshbop under $ZBPATH_MIGRATE, run 'zshbop migrate'";
                        FOUND="1"
                fi
        done
        if [[ "$FOUND" == "0" ]]; then
                _debug " -- Don't need to migrate legacy zshbop"
        fi
}

# -- zshbop_version
help_zshbop[version]='Get version information'
zshbop_version () {
        _debug_function
        echo "-- Version: $fg[green]$ZSHBOP_VERSION/$ZSHBOP_BRANCH/$ZSHBOP_COMMIT$reset_color .zshrc MD5: $fg[green]$ZSHBOP_CURRENT_ZSHRC_MD5$reset_color --"
}

# -- zshbop_color
help_zshbop[colors]='List variables for using color'
zshbop_colors () {
        _debug_function
	for k in ${color}; do
	   print -- key: $k
	done
}

# -- zshbop_help
help_zshbop[help]='This help screen :)'
zshbop_help () {
        _debug_function
        echo "-- zshbop help ------------"
        echo ""
        for key in ${(kon)help_zshbop}; do
        	printf '%s\n' "  ${(r:25:)key} - ${help_zshbop[$key]}"
        done
        echo ""
}

check_nala () {
        _debug_function
        _debug "Checking if nala is installed"
        if [[ $(_cexists nala ) ]]; then
	        _debug "nala installed - running zsh completions"
	        source /usr/share/bash-completion/completions/nala
        fi
}

# --------------
# -- Always Last
# --------------

zshbop () {
        if [[ $1 == "help" ]] || [[ ! $1 ]]; then
                zshbop_help
        elif [[ $1 ]]; then
	        _debug "-- Running zshbop $1"
                zshbop_cmd=(zshbop_${1})
                $zshbop_cmd $@
        fi
}