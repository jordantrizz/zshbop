#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- functions.zsh -- This file contains all the required zshbop functions for the main .zshrc script.
# -----------------------------------------------------------------------------------
_debug_load

# -----------
# -- ZSHBOP Aliases
# -----------
alias update="zshbop_update"
alias rld="zshbop_reload"
alias urld="zshbop_update;zshbop_reload"
alias qrld="zshbop_reload -q"
alias qurld="zshbop_update;zshbop_reload -q"
alias zb="zshbop"
alias init="init_zshbop"
alias zbr="cd $ZBR"
alias motd="init_motd"
alias report="zshbop_report"
alias omz-plugins='escho "OMZ Plugins $OMZ_PLUGINS"'

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
alias cc="zshbop_cacheclear"
zshbop_cacheclear () {   
    _log "${funcstack[1]}:start"
    _loading "**** Start ZSH cache clear ****" 
	_loading2 "Clearing plugin manager cache"
	if [[ ${ZSHBOP_PLUGIN_MANAGER} == "init_antigen" ]]; then
      _loading2 $(antigen reset)
	elif [[ $ZSHBOP_PLUGIN_MANAGER == "init_antidote" ]]; then
	    if [[ -a ${ANTIDOTE_STATIC} ]]; then
	      _loading2 "Removing antidote static file cache"
	      rm "${ANTIDOTE_STATIC}"
	    else
	      _loading2 "${ANTIDOTE_STATIC} doesn't exist"
	    fi
	fi

	_loading2 "Clearing zshrc.zwc file"
	rm -f ~/.zshrc.zwc
    _loading "**** End ZSH cache clear ****"
    echo ""
}

# -- zshbop_scc
alias scc="zshbop_scc"
help_zshbop[zshbop_scc]='Clear everything, including zsh autocompletion'
zshbop_scc () {
    _loading "Clearing rm ~/.zcompdump*"
    rm -f ~/.zcompdump*
}

# -------------------
# -- zshbop_reload ()
# --
# -- reload zshbop
# -------------------
help_zshbop[reload]='Reload zshbop'
zshbop_reload () {
    _log "${funcstack[1]}:start"
    if [[ $1 == "-q" ]]; then
        _loading "Quick reload of zshbop"
        export RUN_REPORT=0
        zshbop_cacheclear
        source $ZBR/lib/*.zsh
        source $ZBR/cmds/*.zsh
        _loading "Load zshbop custom config"
        zshbop_load_custom
    else
        _loading "Reloading zshbop"
        export RUN_REPORT=1
        export ZSHBOP_RELOAD=1
        zshbop_cacheclear
        _log "Running exec zsh"
	    exec zsh
    fi
}

# ---------------------
# -- zshbop_startup ()
# --
# -- Run zshbop startup
# ---------------------
help_zshbop[startup]='Run zshbop startup'
zshbop_startup () {
	_debug_all
	init_motd
}

# --------------------------
# -- zshbop_branch ($branch)
# --
# -- Change branch of zshbop
# --------------------------
help_zshbop[branch]='Run main or dev branch of zshbop'
zshbop_branch  () {
        _debug_all
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
	_debug_all

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
    _log "${funcstack[1]}:start"
	_debug_all
    _loading "START UPDATING ZSHBOP"
        
    # -- print out zshbop version
    zshbop_version
        
    # -- Pull zshbop down from git using current branch
    _loading2 "Pulling zshbop updates"

    # -- Changed branch from develop to dev - 2021-05-01
    if [[ $ZSHBOP_BRANCH == 'develop' ]]; then
    	_debug "Detected old branch name develop"
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT checkout dev
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT pull
    else
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT pull
    fi

	# Check if .zshrc is out of date - Called from script directly versus cached functions
    _loading2 "Previous version check"
	source $ZBR/lib/functions.zsh 
    zshbop_previous-version-check

    # Update repos
	repos update
	
	# Update $ZBC aka custom zshbop directory
	_loading2 "Updating custom zshbop directory $ZBC"
	if [[ $ZBC ]]; then
		_loading2 "Found zshbop custom, running git pull if a git repostiory"
		git --git-dir=${ZBC}/.git --work-tree=${ZBC} pull
	else
		_loading2 "No zshbop-custom to update"
	fi

    # -- Update $ZSHBOP_UPDATE_GIT git repositories from custom config.
    _loading2 "Updating \$ZSHBOP_UPDATE_GIT git repositores."
    if [[ $ZSHBOP_UPDATE_GIT ]]; then
        _debug "Found \$ZSHBOP_UPDATE_GIT which continas $ZSH_UPDATE_GIT"
        for GIT in ${ZSHBOP_UPDATE_GIT[@]}; do
            _debug "Checking $GIT"
            [[ -d "$HOME/$GIT" ]] && ZUG="$HOME/$GIT"
            [[ -d "$GIT_HOME/$GIT" ]] && ZUG="$HOME/$GIT"
            [[ -d $GIT ]] && ZUG="$GIT"
            if [[ -d ${ZUG} ]]; then 
                _loading2 "Updating ${ZUG}"
                git --git-dir=${ZUG}/.git --work-tree=${ZUG} pull
            else
                _error "Couldn't find ${GIT}"
            fi
        done
    fi

    # Reload scripts
    _warning "Type zb reload to reload zshbop, or restart your shell."
    _banner_yellow "**** END UPDATING ZSHBOP ****"
    echo ""
}
# -----------------------------------
# -- zshbop_pervious-version-check ()
# -----------------------------------
help_zshbop[previous-version-check]='Checking if \$HOME/.zshrc is pre v1.1.3 and replacing.'
zshbop_previous-version-check () {
        _debug_all

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
	_debug_all
        _log "Checking for legacy zshbop"        
        FOUND="0"
        for ZBPATH_MIGRATE in "${ZSHBOP_MIGRATE_PATHS[@]}"; do
            if [ -d "$ZBPATH_MIGRATE" ]; then
                    _error "Detected old zshbop under $ZBPATH_MIGRATE, run 'zshbop migrate'";
                    FOUND="1"
            fi
        done
        if [[ "$FOUND" == "0" ]]; then
            _dlog "Don't need to migrate legacy zshbop"
        fi

        _log "-- Checking for github modules"
        if [ -d "$ZSHBOP_ROOT/ultimate-linux-tool-box" ]; then
            _debug "Found old ultimate-linux-tool-box"
            _warning "Found ultimate-linux-tool-box run 'zshbop migrate'"
        else
            _log "Didn't find ultimate-linux-tool-box"
        fi

        if [ -d "$ZSHBOP_ROOT/ultimate-wordpress-tools" ]; then
            _debug "Found old ultimate-wordpress-tools"
            _warning "Found ultimate-wordpress-tools run 'zshbop migrate'"
        else
            _log "Didn't find ultimate-wordpress-tools"
        fi
        
}
# --------------------
# -- zshbop_migrate ()
# --------------------
help_zshbop[migrate]='Migrate old zshbop to new zshbop'
zshbop_migrate () {
	_debug_all
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
        echo "zshbop Version: ${fg[green]}${ZSHBOP_VERSION}/${fg[black]}${bg[cyan]}${ZSHBOP_BRANCH}${reset_color}"
}

help_zshbop[commit]='Get commit information'
zshbop_commit () {        
        echo "zshbop Commit: ${fg[black]}${bg[cyan]}${ZSHBOP_BRANCH}${reset_color}${fg[green]}/$ZSHBOP_COMMIT${RSC} | Install .zshrc MD5: $fg[green]$ZSHBOP_HOME_MD5${RSC}"
}

# --------------------------
# -- zshbop_version_check ()
# --------------------------
help_zshbop[version-check]='Check zshbop version'
zshbop_version-check () {    		
	# -- check .zshrc
	_loading "zshbop Version Check"
    zshbop_version
    echo "-- Latest zshbop .zshrc: $fg[green]$ZSHBOP_LATEST_MD5${RSC}"
    echo "-- \$ZSHBOP/.zshrc: $fg[green]$ZSHBOP_INSTALL_MD5${RSC}"
    echo "-- \$HOME/.zshrc MD5: $fg[green]$ZSHBOP_HOME_MD5${RSC}"
        
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
    _debug_all        
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
            else
                _error "$ZSHBOP_ROOT/.debug doesn't exist"
                rld
            fi
            if [[ -f $ZSHBOP_ROOT/.verbose ]]; then
                rm $ZSHBOP_ROOT/.verbose
            else
                _error "$ZSHBOP_ROOT/.verbose doesn't exist"
            fi
            echo "Reloading to disable debug"
            rld
    elif [[ $1 == "verbose" ]] || [[ $2 == "verbose" ]]; then
            echo "Turning debug verbose on"
            _debug "Turning debug verbose on"
            touch $ZSHBOP_ROOT/.verbose
            touch $ZSHBOP_ROOT/.debug
            echo "Reloading to enable debug verbose"
            rld
    else
            _error "nothing passed"
            echo "Usage: debug <on|off|verbose>"
            echo "Debug is $ZSH_DEBUG"
    fi
}

# ------------------
# -- zshbop_color ()
# ------------------
help_zshbop[colors]='List variables for using color'
zshbop_colors () {
    _debug_all
	
    _loading "How to use color"
    echo "  Foreground \$fg[blue] \$fg[red] \$fg[yellow] \$fg[green]"
    echo "  Background \$fg[blue] \$fg[red] \$fg[yellow] \$fg[green]"
    echo "  Reset Color: \${RSC}"
    echo ""

	_loading "Listing all color functions"
	for func in ${COLOR_FUNCTIONS[@]}; do
		${=func} "$func"
	done
    echo ""
    
    _loading "Listing colors available"
    colors-print
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
	if [[ $1 == "-q" ]]; then
        [[ -f $HOME/.zshbop.conf ]] && source $HOME/.zshbop.conf
    else
        # -- Check for $HOME/.zshbop.config, load last to allow overwritten core functions
        _log "Checking for $HOME/.zshbop.conf"
        if [[ -f $HOME/.zshbop.conf ]]; then
            ZSHBOP_CUSTOM="$HOME/.zshbop.conf"
            _loading3 "Loaded custom zshbop config at $ZSHBOP_CUSTOM"
            source $ZSHBOP_CUSTOM
        else
            _warning "No custom zshbop config found. Type zshbop custom for more information"
        fi
    fi
}

# --------------
# -- zshbop_help
# --------------
help_zshbop[help]='zshbop help screen'
zshbop_help () {
        _debug_all
        _loading "-- zshbop help ------------"
        echo ""
        for key in ${(kon)help_zshbop}; do
            printf '%s\n' "  ${(r:25:)key} - ${help_zshbop[$key]}"
        done
        echo ""
}

# --------------
# -- zshbop_report
# --------------
help_zshbop[report]='Print out errors and warnings'
zshbop_report () {
    local LOG_LEVEL="$1"
    local SHOW_LEVEL=()
    local TAIL_LINES=""

    # -- specify how many lines to show
    if [[ -z $2 ]]; then
        TAIL_LINES="10"
    else
        TAIL_LINES="$2"
    fi

    # -- if no log level passed, set to errors
    if [[ -z $LOG_LEVEL ]]; then
        SHOW_LEVEL=("WARNING" "ALERT" "ERROR")
        _loading3 "No log level specified"
    elif [[ $LOG_LEVEL == "help" ]]; then
        echo "Usage: report <all|debug|error|warning|alert|notice|log>"
    elif [[ $LOG_LEVEL == "less" ]]; then
        less $SCRIPT_LOG
    elif [[ $LOG_LEVEL = "all" ]]; then        
        SHOW_LEVEL=("ERROR" "WARNING" "ALERT" "LOG")
    elif [[ $LOG_LEVEL = "debug" ]]; then
        SHOW_LEVEL=("DEBUG")
    elif [[ $LOG_LEVEL = "error" ]]; then
        SHOW_LEVEL=("ERROR")
    elif [[ $LOG_LEVEL = "warning" ]]; then
        SHOW_LEVEL=("WARNING")
    elif [[ $LOG_LEVEL = "alert" ]]; then
        SHOW_LEVEL=("ALERT")
    elif [[ $LOG_LEVEL = "log" ]]; then
        SHOW_LEVEL=("LOG")
    elif [[ $LOG_LEVEL = "notice" ]]; then
        SHOW_LEVEL=("NOTICE")
    else        
        _error "Unknown $LOG_LEVEL"
    fi

    # -- start
    _debug_all
    _loading "-- zshbop report ------------"
    _loading3 "Showing - ${SHOW_LEVEL[@]}"
    # -- print out logs
    for LOG in $SHOW_LEVEL; do
        _loading2 "-- $LOG ------------"
        _loading3 "Last $TAIL_LINES $LOG from - grep "\[${LOG}\]" $SCRIPT_LOG"
        grep "\[$LOG\]" $SCRIPT_LOG | tail -n $TAIL_LINES
    done
    echo ""
}

# ==============================================
# -- system_check - check usualy system stuff
# ==============================================
help_zshbop[systemcheck]='Print out errors and warnings'
zshbop_systemcheck () {
	# -- start
	_debug_all
	
    # -- network interfaces
    _debug "Network interfaces"
    _loading3 "Checking network interfaces"
    interfaces | sed 's/^/  /'

	# -- check swappiness
	_debug "Checking swappiness"
    echo "$(_loading3 "Swappiness") $(swappiness)"
	
	# -- check disk space
	_debug "Checking disk space on $MACHINE_OS"
    echo "$(_loading3 "Checking disk space") $(check_diskspace)"

	# -- check block devices
    _debug "Checking block devices"
    echo "$(_loading3 "Checking block devices") $(check_blockdevices)"

    # -- Quick CPU/Mem
    _debug "Checking CPU/Mem"
    echo "$(_loading3 "Checking CPU/Mem") $(system-specs)"
}

# --------------
# -- zshbop_check
# --------------
help_zshbop[check]='Check environment for installed software and tools'
function zshbop_check () {
    _log "${funcstack[1]}:start"
    _loading "Checking environment"
    _loading3 "Checking if required tools are installed"
    for i in $REQUIRED_SOFTWARE; do
        _cexists $i
        if [[ $? == "0" ]]; then
                echo "$i is $bg[green]$fg[white] INSTALLED. $reset_color"
        else
                echo "$i is $bg[red]$fg[white] MISSING. $reset_color"
        fi
    done

    _loading3 "Checking for default tools"
    for i in $DEFAULT_TOOLS; do
        _cexists $i
        if [[ $? == "0" ]]; then
                echo "$i is $bg[green]$fg[white] INSTALLED. $reset_color"
        else
                echo "$i is $bg[red]$fg[white] MISSING. $reset_color"
        fi
    done

    _loading2 "Checking for extra tools"
    for i in $EXTRA_TOOLS; do
    _cexists $i
    if [[ $? == "0" ]]; then
                    echo "$i is $bg[green]$fg[white] INSTALLED. $reset_color"
            else
                    echo "$i is $bg[red]$fg[white] MISSING. $reset_color"
    fi
    done
    _loading "Run zshbop install-env to install above tools"
    _log "${funcstack[1]}:end"
}

# --------------------------------
# -- zshbop_install-env
# --------------------------------
help_zshbop[install-env]='Install environment tools'
fucntion zshbop_install-env () {
    _log "${funcstack[1]}:start"
    _loading "Installing environment"
    _loading3 "Required tools - ${REQUIRED_SOFTWARE[@]}"
    _loading2 "Generating list of required tools that need to be insstalled"
    # -- install required tools
    for i in ${REQUIRED_SOFTWARE[@]}; do
        _cexists $i
        if [[ $? == "1" ]]; then
            _debug "Adding $i to list of tools to install"
            PKG_TO_INSTALL+=("$i")  
        fi
    done
    _loading3 "Packages to install - $PKG_TO_INSTALL"

    read -q "REPLY?Proceed with install? [y/n] "
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        _loading3 "Installing - $PKG_TO_INSTALL"
        eval $PKG_MANAGER install $PKG_TO_INSTALL
    else
        _loading3 "Not installing - $PKG_TO_INSTALL"
    fi
    
    _log "${funcstack[1]}:stop"
}


# ==============================================
# ==============================================
# ==============================================
# ==============================================

# --------------
# -- Always Last
# --------------

zshbop () {
	_debug_all 
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


