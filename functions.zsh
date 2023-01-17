# -----------------------------------------------------------------------------------
# -- functions.zsh
# -- This file contains all the required zshbop functions for the main .zshrc script.
# -----------------------------------------------------------------------------------

#######################################
echo "\e[43;30m * Loading ${0:a} \e[0m"

# -----------
# -- ZSHBOP Aliases
# -----------
alias update="zshbop_update"
alias rld="zshbop_reload"
alias urld="zshbop_update;zshbop_reload"
alias zb="zshbop"
alias init="init_zshbop"
alias _debug_function="_debug_all"
alias zbr="cd $ZBR"
alias motd="init_motd"

##########################################
# -------------------
# -- zshbop functions
# -------------------
##########################################

# -------------------------------------
# -- cc ()
# --
# -- clear cache for various tools
# -------------------------------------
help_zshbop[cc]='Clear cache for antigen + more'
alias cc="zshbop_cc"
zshbop_cacheclear () {
	_loading "Clearing plugin manager cache"
	if [[ ${ZSHBOP_PLUGIN_MANAGER} == "init_antigen" ]]; then
      _loading_grey $(antigen reset)
	elif [[ $ZSHBOP_PLUGIN_MANAGER == "init_antidote" ]]; then
	    if [[ -a ${ANTIDOTE_STATIC} ]]; then
	      _loading_grey "Removing antidote static file cache"
	      rm "${ANTIDOTE_STATIC}"
	    else
	      _loading_grey "${ANTIDOTE_STATIC} doesn't exist"
	    fi
	fi

	_loading "Clearing zshrc.zwc file"
	rm -f ~/.zshrc.zwc
}

# -------------------
# -- zshbop_reload ()
# --
# -- reload zshbop
# -------------------
help_zshbop[reload]='Reload zshbop'
zshbop_reload () {
    _debug_function
    _debug "Clearing cache"
    zshbop_cacheclear
	source $HOME/.zshrc
	zshbop_version-check
	echo ""
	_warning "You may have to close your shell and restart it to see changes"
    echo ""
}

# ---------------------
# -- zshbop_startup ()
# --
# -- Run zshbop startup
# ---------------------
help_zshbop[startup]='Run zshbop startup'
zshbop_startup () {
	_debug_function
	init_motd
}

# --------------------------
# -- zshbop_branch ($branch)
# --
# -- Change branch of zshbop
# --------------------------
help_zshbop[branch]='Run main or dev branch of zshbop'
zshbop_branch  () {
        _debug_function
		if [[ -n $2 ]]; then
	        echo "	-- Switching to $2 branch"
    		GIT_CHECKOUT=$(git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT checkout $2)
    		if [[ $? -ge "1" ]]; then
    			_error "Branch doesn't seem to exist"
    		fi
        elif [ -z $2 ]; then
                echo "	-- zshbop: $ZSHBOP_ROOT branch: $ZSHBOP_BRANCH ----"
                echo "	-- To switch branch type 'zshbop branch dev' or 'zshbop branch main'"
        else
        	_error "Unknown $@"
        fi
}

# ----------------------------
# -- zshbop_check-updates ()
# --
# -- Check for zshbop updates.
# ----------------------------
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

# -------------------
# -- zshbop_update ()
# --
# -- Update ZSHBOP
# -------------------
help_zshbop[update]='Update zshbop'
zshbop_update () {
	_debug_function
    _loading "UPDATING ZSHBOP"
        
    # -- print out zshbop version
    zshbop_version
        
    # -- Pull zshbop down from git using current branch
    _loading2 "Pulling zshbop updates"

    # -- Changed branch from develop to dev
    if [[ $ZSHBOP_BRANCH == 'develop' ]]; then
    	_debug "Detected old branch name develop"
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT checkout dev
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT pull
    else
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT pull
    fi

	# Check if .zshrc is out of date.
	# Called from script directly versus cached functions
	$ZSHBOP_ROOT/zshbop.zsh previous-version-check

    # Update repos
	repos update
	
	# Update $ZBC aka custom zshbop directory
	_loading "Updating custom zshbop directory $ZBC"
	if [[ $ZBC ]]; then
		_loading2 "Found zshbop custom, running git pull if a git repostiory"
		git --git-dir=${ZBC}/.git --work-tree=${ZBC} pull
	else
		_loading2 "No zshbop-custom to update"
	fi

    # Reload scripts
    _warning "Type zb reload to reload zshbop, or restart your shell."
}
# -----------------------------------
# -- zshbop_pervious-version-check ()
# -----------------------------------
help_zshbop[previous-version-check]='Checking if \$HOME/.zshrc is pre v1.1.3 and replacing.'
zshbop_previous-version-check () {
        _debug_function

        # Replacing .zshrc previous to v1.1.2 256bb9511533e9697f639821ba63adb9
        _debug " -- Current $HOME/.zshrc md5 is - $ZSHBOP_HOME_MD5"
        _debug " -- zshbop .zshrc md5 is - $ZSHBOP_LATEST_MD5"
        if [[ "$ZSHBOP_HOME_MD5" != "$ZSHBOP_LATEST_MD5" ]]; then
                _error "-- Found old .zshrc"
                _notice "-- Replacing $HOME/.zshrc"
                cp $ZSHBOP_ROOT/.zshrc $HOME/.zshrc
        else
        	_debug " -- No need to fix .zshrc"
        fi
}

# -----------------------
# -- zshbop_migrate-check
# -----------------------
help_zshbop[migrate-check]='Check if running old zshbop.'
zshbop_migrate-check () {
	_debug_function
        _loading2 "Checking for legacy zshbop"        
        FOUND="0"
        for ZBPATH_MIGRATE in "${ZSHBOP_MIGRATE_PATHS[@]}"; do
                if [ -d "$ZBPATH_MIGRATE" ]; then
                        _error "Detected old zshbop under $ZBPATH_MIGRATE, run 'zshbop migrate'";
                        FOUND="1"
                fi
        done
        if [[ "$FOUND" == "0" ]]; then
                _loading2 "Don't need to migrate legacy zshbop"
        fi

        _banner_yellow "-- Checking for github modules"
        if [ -d "$ZSHBOP_ROOT/ultimate-linux-tool-box" ]; then
                _debug "Found old ultimate-linux-tool-box"
                _warning "Found ultimate-linux-tool-box run 'zshbop migrate'"
        else
                _success "Didn't find ultimate-linux-tool-box"
        fi

        if [ -d "$ZSHBOP_ROOT/ultimate-wordpress-tools" ]; then
                _debug "Found old ultimate-wordpress-tools"
                _warning "Found ultimate-wordpress-tools run 'zshbop migrate'"
        else
                _success "Didn't find ultimate-wordpress-tools"
        fi
        
}
# --------------------
# -- zshbop_migrate ()
# --------------------
help_zshbop[migrate]='Migrate old zshbop to new zshbop'
zshbop_migrate () {
	_debug_function
        _debug " -- Migrate old zshbop to legacy zshbop"
        FOUND="0"
        for ZBPATH_MIGRATE in "${ZSHBOP_MIGRATE_PATHS[@]}"; do
                if [ -d "$ZBPATH_MIGRATE" ]; then
                		_success "Found legacy zshbop...migrating"
                        echo " -- Moving $ZBPATH_MIGRATE to ${ZBPATH_MIGRATE}bop"
                        sudo mv $ZBPATH_MIGRATE ${ZBPATH_MIGRATE}bop
                        echo " -- Copying ${ZBPATH_MIGRATE}bop/.zshrc to your $HOME/.zshrc"
                        cp ${ZBPATH_MIGRATE}bop/.zshrc $HOME/.zshrc
                        FOUND="1"
                fi
        done
        if [[ "$FOUND" == "0" ]]; then
                _debug " -- Don't need to migrate legacy zshbop"
        fi
        
        _debug "-- Checking for github modules"
        if [ -d "$ZSHBOP_ROOT/ultimate-linux-tool-box" ]; then
                _debug "Found old ultimate-linux-tool-box"
                _warning "Found ultimate-linux-tool-box, removing folder"
                rm -r $ZSHBOP_ROOT/ultimate-linux-tool-box
        else
                _debug "Didn't find ultimate-linux-tool-box"
        fi

        if [ -d "$ZSHBOP_ROOT/ultimate-wordpress-tools" ]; then
                _debug "Found old ultimate-wordpress-tools"
                _warning "Found ultimate-wordpress-tools, removing folder."
                rm -r $ZSHBOP_ROOT/ultimate-wordpress-tools
        else
                _debug "Didn't find ultimate-wordpress-tools"
        fi
}

# --------------------
# -- zshbop_version ()
# --------------------
help_zshbop[version]='Get version information'
zshbop_version () {
        _debug_function
        _loading "zshbop Version"
        echo "Version: ${fg[green]}${ZSHBOP_VERSION}/${fg[white]}${bg[cyan]}${ZSHBOP_BRANCH}${reset_color}${fg[green]}/$ZSHBOP_COMMIT$reset_color"
        echo "Install .zshrc MD5: $fg[green]$ZSHBOP_HOME_MD5$reset_color --"
}

# --------------------------
# -- zshbop_version_check ()
# --------------------------
help_zshbop[version-check]='Check zshbop version'
zshbop_version-check () {
  _debug_function
	zshbop_version
	
	# -- check .zshrc
	_loading "zshbop Version Check"
    echo "-- Latest zshbop .zshrc: $fg[green]$ZSHBOP_LATEST_MD5$reset_color"
    echo "-- \$ZSHBOP/.zshrc: $fg[green]$ZSHBOP_INSTALL_MD5$reset_color"
    echo "-- \$HOME/.zshrc MD5: $fg[green]$ZSHBOP_HOME_MD5$reset_color"
        
    _loading2 "Checking if $HOME/.zshrc is the same as $ZSHBOP/.zshrc"
    if [[ $ZSHBOP_HOME_MD5 == $ZSHBOP_INSTALL_MD5 ]]; then
      _success "  \$HOME/.zshrc and  \$ZSHBOP/.zshrc are the same."
    else
      _error "  \$HOME/.zshrc and \$ZSHBOP/.zshrc are the different."
    fi
    
    # -- checking branch git commit versus current commit
    _loading "Checking for branch updates"
    echo "-- Current Commit : $fg[green]"
    
}

# ------------------
# -- zshbop_debug ()
# ------------------
help_zshbop[debug]='Turn debug on and off'
alias debug=zshbop_debug
zshbop_debug () {
        _debug_function        
        echo "test $@"
        if [[ $1 == "on" ]] || [[ $2 == "on" ]]; then
                echo "Turning debug on"
                _debug "Turning debug on"
                touch $ZSHBOP_ROOT/.debug
                echo "Reloading to enable debug"
                rld
        elif [[ $1 == "off" ]] || [[ $2 == "off" ]]; then
                echo "Turning debug off"
                _debug "Turning debug off"
                if [[ -f $ZSHBOP_ROOT/.debug ]]; then
	                rm $ZSHBOP_ROOT/.debug
    	            echo "Reloading to disable debug"
    	        else
    	        	_error "$ZSHBOP_ROOT/.debug doesn't exist"
	                rld
	            fi
        else
				_error "nothing passed"
                echo "Usage: debug <on|off>"
                echo "Debug is $ZSH_DEBUG"
        fi
}

# ------------------
# -- zshbop_color ()
# ------------------
help_zshbop[colors]='List variables for using color'
zshbop_colors () {
        _debug_function
        _loading "Color names"
        for k in ${color}; do
		   print -- key: $k
		done

        _loading "How to use color"
        echo "  Foreground \$fg[blue] \$fg[red] \$fg[yellow] \$fg[green]"
        echo "  Background \$fg[blue] \$fg[red] \$fg[yellow] \$fg[green]"
        echo "  Reset Color: \$reset_color"

        _loading "-- Color Options"
        _banner_red "_banner_red"
        _banner_green "_banner_green"
        _banner_yellow "_banner_yellow"
        _banner_grey "_banner_grey"
        _error "_error"
        _warning "_warning"
        _success "_success"
        _notice "_notice"
		_noticebg "_noticebg" 
		_noticefg "_noticefg"
		_loading "_loading"
		_loading2 "_loading"
}

# ----------------
# -- zshbop_custom
# ----------------
help_zshbop[custom]='Custom zshbop configuration'
zshbop_custom () {
	_banner_green "Instructions on how to utilize custom zshbop configuration."
	echo " - Create a file called .zshbop.custom in your /$HOME directory"
	echo " - Done!"
	echo " - You can also copy the .zshbop.custom file within this repository as a template"
}

# ---------------------
# -- zshbop_load_custom
# ---------------------
help_zshbop[load_custom]='Load zshbop custom config'
zshbop_load_custom () {
	# -- Check for $HOME/.zshbop.config, load last to allow overwritten core functions
	_loading "Checking for $HOME/.zshbop.conf"
    if [[ -f $HOME/.zshbop.conf ]]; then
    	ZSHBOP_CUSTOM="$HOME/.zshbop.conf"
        _loading_grey "Loaded custom zshbop config at $ZSHBOP_CUSTOM"
        source $ZSHBOP_CUSTOM
    else
    	_error "No custom zshbop config found. Type zshbop custom for more information"
    fi
}

# --------------
# -- zshbop_help
# --------------
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

# --------------
# -- Always Last
# --------------

zshbop () {
	_debug_function 
    if [[ -z $1 ]]; then
		zshbop_help
    elif [[ $1 == "help" ]]; then    
		zshbop_help        	
    elif [[ -n $1 ]]; then
		_debug "-- Running zshbop $1"
        zshbop_cmd=(zshbop_${1})
        $zshbop_cmd $@
    fi
}