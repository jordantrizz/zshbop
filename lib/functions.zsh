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
help_zshbop[cache-clear]='Clear cache for antigen + more'
alias cc="zshbop_cache-clear"
zshbop_cache-clear () {   
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

# -- cache-clear-super
alias scc="cache-clear-super"
help_zshbop[cache-clear-super]='Clear everything, including zsh autocompletion'
zshbop_cache-clear-super () {
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
        zshbop_cache-clear
        source $ZBR/lib/*.zsh
        source $ZBR/cmds/*.zsh
        _loading "Load zshbop custom config"
        zshbop_custom-load
    else
        _loading "Reloading zshbop"
        export RUN_REPORT=1
        export ZSHBOP_RELOAD=1
        zshbop_cache-clear
        _log "Running exec zsh"
	    exec zsh
    fi
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
	        _loading "Switching to $2 branch"
    		GIT_CHECKOUT=$(git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT checkout $2)
            _debug "GIT_CHECKOUT: $GIT_CHECKOUT"
            if [[ $? -eq "0" ]]; then
                _success " --Switched to $2 branch, pulling latest changes"
                git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT pull 
            else
                _error " -- Failed to switch to $2 branch"
            fi
        elif [[ $? -ge "1" ]]; then
            _error "Branch doesn't seem to exist"
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

# --------------------
# -- zshbop_version ()
# --------------------
help_zshbop[version]='Get version information'
zshbop_version () {
        echo "zshbop Version: ${fg[green]}${ZSHBOP_VERSION}/${fg[black]}${bg[cyan]}${ZSHBOP_BRANCH}${reset_color}/$ZSHBOP_COMMIT${RSC}"
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
	_loading "Instructions on how to utilize custom zshbop configuration."
	echo " - Create a file called .zshbop.custom in your /$HOME directory"
	echo " - You can also copy the .zshbop.custom file within this repository as a template"
}

# ---------------------
# -- zshbop_custom-load
# ---------------------
help_zshbop[custom-load]='Load zshbop custom config'
zshbop_custom-load () {
	if [[ $1 == "-q" ]]; then
        [[ -f $HOME/.zshbop.conf ]] && source $HOME/.zshbop.conf
    else
        # -- Check for $HOME/.zshbop.config, load last to allow overwritten core functions
        _log "Checking for $HOME/.zshbop.conf"
        if [[ -f $HOME/.zshbop.conf ]]; then
            ZSHBOP_CUSTOM_CFG="$HOME/.zshbop.conf"
            _loading3 "Loaded custom zshbop config at $ZSHBOP_CUSTOM_CFG"
            source $ZSHBOP_CUSTOM_CFG
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
function zshbop_report () {
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
        echo "Usage: report <all|debug|error|warning|alert|notice|log|less|faults> <lines>"
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
    elif [[ $LOG_LEVEL = "notice" ]]; then
        SHOW_LEVEL=("NOTICE")
    elif [[ $LOG_LEVEL = "log" ]]; then
        SHOW_LEVEL=("LOG")
    elif [[ $LOG_LEVEL == "less" ]]; then
        less $SCRIPT_LOG
    elif [[ $LOG_LEVEL = "faults" ]]; then
        SHOW_LEVEL=("ERROR" "WARNING" "ALERT")
    else        
        _error "Unknown $LOG_LEVEL"
    fi

    # -- start
    _debug_all
    _loading "-- zshbop report ------------"
    [[ $LOG_LEVEL != "faults" ]] && _loading3 "Showing - ${SHOW_LEVEL[@]}"
    # -- print out logs
    for LOG in $SHOW_LEVEL; do
        [[ $LOG_LEVEL != "faults" ]] && _loading2 "-- $LOG ------------"
        [[ $LOG_LEVEL != "faults" ]] && _loading3 "Last $TAIL_LINES $LOG from - grep "\[${LOG}\]" $SCRIPT_LOG"
        grep "\[$LOG\]" $SCRIPT_LOG | tail -n $TAIL_LINES
    done
    echo ""
}

# ==============================================
# -- system_check - check usualy system stuff
# ==============================================
help_zshbop[check-system]='Print out errors and warnings'
function zshbop_check-system () {
	# -- start
	_debug_all

    # -- CPU
    _debug "Checking CPU"
    echo "$(_loading3 $(cpu))"

    # -- MEM
    _debug "Checking memory"
    echo "$(_loading3 $(mem))"
	
    # -- network interfaces
    _debug "Network interfaces"
    _loading3 "Checking network interfaces - $(interfaces)"

	# -- check swappiness
	_debug "Checking swappiness"
    echo "$(_loading3 "Swappiness") $(swappiness)"
	
	# -- check disk space
	_debug "Checking disk space on $MACHINE_OS"
    echo "$(_loading3 "Checking disk space") $(check_diskspace)"

	# -- check block devices
    _debug "Checking block devices"
    echo "$(_loading3 "Checking block devices") $(check_blockdevices)"


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

# -- zshbop_cleanup
help_zshbop[cleanup]='Cleanup old things'
function zshbop_cleanup () {
    _log "${funcstack[1]}:start"
    # -- older .zshrc
    OLD_ZSHRC_MD5SUM=(
        "09fcdc31ca648bb15f7bb7ff90d0539a"
        "256bb9511533e9697f639821ba63adb9"
        "46c094ff2b56af2af23c5b848d46f997"
    )
    ZSHRC_MD5SUM="$(md5sum $HOME/.zshrc | awk {' print $1'})"
    _loading "ZSH Cleanup"
    _log "Checking for old .zshrc against $ZSHRC_MD5SUM"
    if [[ -f $HOME/.zshrc ]]; then
        _log "Found $HOME/.zshrc md5sum:$ZSHRC_MD5SUM"
        for i in $OLD_ZSHRC_MD5SUM; do
            _log "CUR:$ZSHRC_MD5SUM vs OLD:$i"
            if [[ $i == $ZSHRC_MD5SUM ]]; then
                _alert "md5sum matched - Removing old .zshrc"
                rm $HOME/.zshrc
                echo "source $ZSHBOP_ROOT/zshbop.zsh" > $HOME/.zshrc
            else
                _log "md5sum did not match"
            fi
        done
    else
        _log "No .zshrc found"
    fi
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


