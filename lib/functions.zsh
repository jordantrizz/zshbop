#!/usr/bin/env zsh
# =========================================================
# -- functions.zsh
# -- Required zshbop functions for the main .zshrc script.
# =========================================================
_debug_load

# --------------------------------------------------
# -- ZSHBOP Aliases
# --------------------------------------------------
# zbd
help_zshbop_quick[zbd]='Change directory to $ZBR'
alias zbd="cd $ZBR"
# zbr
help_zshbop_quick[zbr]='Reload zshbop'
alias zbr="zshbop_reload"
# zbuf
help_zshbop_quick[zbuf]='Update and reset zshbop'
alias zbuf="git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT pull;git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT reset --hard origin/$ZSHBOP_BRANCH"

# zb
help_zshbop_quick[zb]='zshbop main command'
alias zb="zshbop"

# --------------------------------------------------
# -- Core aliases
# --------------------------------------------------

# init
help_core[init]='Initialize zshbop'
alias init="init_zshbop"

# motd
help_core[motd]='Print out motd'
alias motd="init_motd"

# report
help_core[report]='Print out errors and warnings'
alias report="zshbop_report"

# =========================================================
# -- zshbop functions
# =========================================================

# omz-plugins
help_zshbop[omz-plugins]='Print out enabled OMZ plugins'
alias omz-plugins='echo "OMZ Plugins $OMZ_PLUGINS"'

# =========================================================
# -- cc ()
# --
# -- clear cache for various tools
# =========================================================
help_zshbop[cache-clear]='Clear cache for antigen + more'
function cc () { zshbop_cache-clear }
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
# =========================================================
# -- cache-clear-super
# =========================================================

alias scc="cache-clear-super"
help_zshbop[cache-clear-super]='Clear everything, including zsh autocompletion'
zshbop_cache-clear-super () {
    _loading "Clearing rm ~/.zcompdump*"
    rm -f ~/.zcompdump*
}

# =========================================================
# -- zshbop_reload ()
# --
# -- reload zshbop
# =========================================================
help_zshbop[reload]='Reload zshbop'
zshbop_reload () {
    _log "${funcstack[1]}:start"
    zparseopts -D -E q+=ARG_QUICK c=ARG_COMMAND h+=ARG_HELP s:=ARG_SYSTEM
    local CMD="$1"
    CMD_FILE="$ZBR/cmds/cmds-$CMD.zsh"

    _zshbop_reload_usage () {
        echo "Reload zshbop"
        echo " -h                   Usage"
        echo " -q                   Quick reload"
        echo " -c <commandfile>     Reload Specific Command file"
        echo " -s <system>          Reload specific system"
        echo ""
        echo "Systems: sofware repos"
    }

    if [[ -n $ARG_HELP ]]; then
        _zshbop_reload_usage
        return 1
    elif [[ -n $ARG_COMMAND ]]; then
        if [[ -f $CMD_FILE ]]; then
            _loading "Quick reload of $CMD_FILE"
            source $CMD_FILE
        else
            _error "$CMD_FILE doesn't exist"
        fi
    elif [[ -n $ARG_SYSTEM ]]; then
    SYSTEM=$ARG_SYSTEM[2]
        case $SYSTEM in 
        "software")
            init_software
        ;;
        *)
            _error "Unknown system: $SYSTEM"
        ;;
        esac
        return 1
    elif [[ -n $ARG_QUICK ]]; then
        _loading "Quick reload of zshbop"        
        export ZSHBOP_RELOAD=1
        zshbop_cache-clear
        source $ZSHBOP_ROOT/lib/init.zsh
        init_zbr_cmds
    else
        _loading "Reloading zshbop"        
        export ZSHBOP_RELOAD=1
        zshbop_cache-clear
        _log "Running exec zsh"
        exec zsh
    fi

    #if [[ $1 == "-q" ]]; then
    #        _loading "Quick reload of zshbop"
    #    export RUN_REPORT=0
    #    export ZSHBOP_RELOAD=1
    #    zshbop_cache-clear
    #    init_zshbop
    #else
    #    _loading "Reloading zshbop"
    #    export RUN_REPORT=1
    #    export ZSHBOP_RELOAD=1
    #    zshbop_cache-clear
    #    _log "Running exec zsh"
	#    exec zsh
    #fi
}

# =========================================================
# -- zshbop_branch ($branch)
# --
# -- Change branch of zshbop
# =========================================================
help_zshbop[branch]='Run main or dev branch of zshbop'
zshbop_branch  () {
    _debug_all
    _debugf "args: $@"
    local MODE REMOTE_BRANCH

    # If -r is passed, then remote branch to be pulled and checked out
    zparseopts -D -E r:=ARG_REMOTE h+=ARG_HELP
    if [[ -n $ARG_HELP ]]; then
        echo "Usage: zb branch <branch>"
        echo " -r  <branch>    Pull and checkout remote branch"
        return 1
    fi

    # -- Ensure we have the current branch set, if not set it.
    if [[ -z ${ZSHBOP_BRANCH} ]]; then        
        ZSHBOP_BRANCH=$(git -C $ZSHBOP_ROOT rev-parse --abbrev-ref HEAD 2>/dev/null)
    fi

    # -- Check if were checking out local or remote
    if [[ -n $ARG_REMOTE ]]; then
        MODE="remote"
    elif [[ -n $2 ]]; then
        MODE="local"
    fi
    
    _debugf "MODE: $MODE"
    # Check if -r is set
    if [[ $MODE == "remote" ]];then
        local REMOTE_BRANCH=$ARG_REMOTE[2]
        if [[ -z $REMOTE_BRANCH ]]; then
            _error "No remote branch specified"
            return 1
        fi
        _loading "Changing zshbop Branch to $REMOTE_BRANCH"
        git --git-dir=${ZSHBOP_ROOT}/.git --work-tree=${ZSHBOP_ROOT} fetch
        git -C ${ZSHBOP_ROOT} rebase origin/$(git -C ${ZSHBOP_ROOT} rev-parse --abbrev-ref HEAD)
        git -C ${ZSHBOP_ROOT} checkout $REMOTE_BRANCH
        git -C ${ZSHBOP_ROOT} pull --rebase origin $REMOTE_BRANCH
        ZSHBOP_BRANCH=$(git -C $LMT rev-parse --abbrev-ref HEAD 2>/dev/null)
        _loading2 "Current Branch:${RSC} $ZSHBOP_BRANCH"
        _loading2 "Reloading zshbop"
        lmtr
    elif [[ $MODE == "local" ]]; then
        local BRANCH=$2
        if [[ -n $BRANCH ]]; then
            _loading "Changing zshbop Branch to $BRANCH"
            # Pull down branches
            git --git-dir=${ZSHBOP_ROOT}/.git --work-tree=${ZSHBOP_ROOT} fetch
            git -C ${ZSHBOP_ROOT} rebase origin/$(git -C ${ZSHBOP_ROOT} rev-parse --abbrev-ref HEAD)
            git -C ${ZSHBOP_ROOT} checkout $BRANCH
            git -C ${ZSHBOP_ROOT} pull --rebase origin $BRANCH
            ZSHBOP_BRANCH=$(git -C $LMT rev-parse --abbrev-ref HEAD 2>/dev/null)
            _loading2 "Current Branch:${RSC} $ZSHBOP_BRANCH"
            _loading2 "Reloading zshbop"
            lmtr
        else
            _error "No branch specified"
        fi
    else
        _loading "zshbop Branch"
        _loading2 "Current Branch:${RSC} $ZSHBOP_BRANCH"
        _loading2 "Getting Branches"
        # -- Pull down branches from remote
        git --git-dir=${ZSHBOP_ROOT}/.git --work-tree=${ZSHBOP_ROOT} fetch
        echo ""        
        git --no-pager -C ${ZSHBOP_ROOT} branch -a
        echo "To change branch type: zb branch <branch>"
    fi
}

# =========================================================
# -- zshbop_check-updates ()
# --
# -- Check for zshbop updates.
# =========================================================
help_zshbop[check-updates]='Check for zshbop update, not completed yet'
zshbop_check-updates () {
	_debug_all

    # Sources for version check
	local ZSHBOP_GH_COMMIT_URL="https://api.github.com/repos/jordantrizz/zshbop/commits/$ZSHBOP_BRANCH"
    local ZSHBOP_GH_RELEASE_URL="https://api.github.com/repos/jordantrizz/zshbop/releases/latest"

    # Check for updates
    _loading "Checking for updates"
    _notice "-- Running $ZSHBOP_VERSION/$ZSHBOP_BRANCH/$ZSHBOP_COMMIT checking $ZSHBOP_BRANCH for updates."
    _loading3 "Checking for release update at $ZSHBOP_GH_RELEASE_URL"
    _loading3 "Checking for new commits at $ZSHBOP_GH_COMMIT_URL"

    # -- Get data
    ZSHBOP_LATEST_RELEASE=$(curl -s $ZSHBOP_GH_RELEASE_URL | jq -r '.name')
    typeset -A ZSHBOP_LATEST_DATA
    ZSHBOP_LATEST_DATA[sha]=$(curl -s $ZSHBOP_GH_COMMIT_URL | jq -r '.sha')
    ZSHBOP_LATEST_DATA[author_name]=$(curl -s $ZSHBOP_GH_COMMIT_URL | jq -r '.commit.author.name')
    ZSHBOP_LATEST_DATA[commit_message]=$(curl -s $ZSHBOP_GH_COMMIT_URL | jq -r '.commit.message')

    # Access and print elements from the associative array
    _loading2 "Latest Release: $ZSHBOP_LATEST_RELEASE | Latest Commit: ${ZSHBOP_LATEST_DATA[sha]}"
    _loading3 "Author Name: ${ZSHBOP_LATEST_DATA[author_name]}"
    _loading3 "Commit Message: ${ZSHBOP_LATEST_DATA[commit_message]}"

    # --  Compare releases
    # If not equal update available, if greater than, update available, if less than, running current version
    if [[ $ZSHBOP_VERSION > $ZSHBOP_LATEST_RELEASE ]]; then
            _warning "Woops, we're ahead $ZSHBOP_LATEST_RELEASE is less than $ZSHBOP_VERSION"
    elif [[ $ZSHBOP_VERSION < $ZSHBOP_LATEST_RELEASE ]]; then
            _warning "Update available $ZSHBOP_LATEST_RELEASE"
    elif [[ $ZSHBOP_VERSION != $ZSHBOP_LATEST_RELEASE ]]; then
            _warning "Update available $ZSHBOP_LATEST_RELEASE"
    else
            _success "Running current version $ZSHBOP_LATEST_RELEASE"
    fi

	# -- Compare commits
    if [[ $ZSHBOP_COMMIT != ${ZSHBOP_LATEST_DATA[sha]} ]]; then
           	_warning "Update available ${ZSHBOP_LATEST_DATA[sha]} on $ZSHBOP_BRANCH"
    else
           	_success "No update, on latest ${ZSHBOP_LATEST_DATA[sha]}"
    fi
}


help_zshbop_quick[zbu]='Update zshbop'
function zbu () { zshbop_update }
help_zshbop_quick[zbur]='Update and reload zshbop'
function zbur () { zshbop_update; zshbop_reload }
help_zshbop_quick[zbqr]='Quick reload zshbop'
function zbqr () { zshbop_reload -q }
help_zshbop_quick[zbuqr]='Update and quick reload zshbop'
function zbuqr () { zshbop_update; zshbop_reload -q }
help_zshbop_quick[zbu]='Update zshbop'
function zbu () { zshbop_update }

# =========================================================
# -- zshbop_update ()
# -- Update ZSHBOP
# =========================================================
help_zshbop[update]='Update zshbop'
zshbop_update () {
    _log "${funcstack[1]}:start"
	_debug_all
    _loading "Updating zshbop - $(zshbop_version)"

    # -- Fetch first
    git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT fetch
    [[ $? -ge "1" ]] && { _error "Failed to fetch latest changes"; return 1 }

    # -- Pull zshbop down from git using current branch
    _loading2 "Pulling zshbop updates"
    if [[ $ZSHBOP_BRANCH == 'develop' ]]; then
    	_debugf "Detected old branch name develop"
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT checkout dev
        [[ $? -ge "1" ]] && { _error "Failed to pull latest changes"; return 1 }
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT pull
        [[ $? -ge "1" ]] && { _error "Failed to pull latest changes"; return 1 }
    else
        _loading3 "Fetching $ZSHBOP_BRANCH"
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT fetch
        [[ $? -ge "1" ]] && { _error "Failed to fetch latest changes"; return 1 }

        _loading3 "Pulling down $ZSHBOP_BRANCH"
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT pull
        # -- Check if pull was successful
        [[ $? -ge "1" ]] && { _error "Failed to pull latest changes"; return 1 }
   fi
    echo ""

    # Update repos    
	repos update
    echo ""

	# Update $ZBC aka custom zshbop directory
	_loading "Updating custom zshbop directory $ZBC"
	if [[ $ZBC ]]; then
		_loading2 "Found zshbop custom, running git pull if a git repostiory"
		git --git-dir=${ZBC}/.git --work-tree=${ZBC} pull
	else
		_loading2 "No zshbop-custom to update"
	fi
    echo ""

    # -- Update $ZSHBOP_UPDATE_GIT git repositories from custom config.
    _loading "Updating \$ZSHBOP_UPDATE_GIT git repositores."
    if [[ $ZSHBOP_UPDATE_GIT ]]; then
        _debugf "Found \$ZSHBOP_UPDATE_GIT which continas $ZSH_UPDATE_GIT"
        for GIT in ${ZSHBOP_UPDATE_GIT[@]}; do
            _debugf "Checking $GIT"
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
    echo ""

    # Reload scripts
    _warning "Type zb reload to reload zshbop, or restart your shell."    
    echo ""
}

# =========================================================
# -- zshbop_version ()
# =========================================================
help_zshbop[version]='Get version information'
zshbop_version () {
        echo "zshbop Version: ${fg[green]}${ZSHBOP_VERSION}/${fg[black]}${bg[cyan]}${ZSHBOP_BRANCH}${reset_color}/$ZSHBOP_COMMIT${RSC}"
}

# =========================================================
# -- zshbop_debugf ()
# =========================================================
help_zshbop[debug]='Turn debug on and off'
alias debug=zshbop_debug
zshbop_debugf () {
    _debug_all
    echo "test $@"
    if [[ $1 == "on" ]] || [[ $2 == "on" ]]; then
            echo "Turning debug on"
            _debugf "Turning debug on"
            touch $ZSHBOP_ROOT/.debug
            echo "Reloading to enable debug"
            zshbop_reload
    elif [[ $1 == "off" ]] || [[ $2 == "off" ]]; then
            echo "Turning debug off"
            _debugf "Turning debug off"
            if [[ -f $ZSHBOP_ROOT/.debug ]]; then
                rm $ZSHBOP_ROOT/.debug
            else
                _error "$ZSHBOP_ROOT/.debug doesn't exist"
                zshbop_reload
            fi
            if [[ -f $ZSHBOP_ROOT/.verbose ]]; then
                rm $ZSHBOP_ROOT/.verbose
            else
                _error "$ZSHBOP_ROOT/.verbose doesn't exist"
            fi
            echo "Reloading to disable debug"
            zshbop_reload
    elif [[ $1 == "verbose" ]] || [[ $2 == "verbose" ]]; then
            echo "Turning debug verbose on"
            _debugf "Turning debug verbose on"
            touch $ZSHBOP_ROOT/.verbose
            touch $ZSHBOP_ROOT/.debug
            echo "Reloading to enable debug verbose"
            zshbop_reload
    else
            _error "nothing passed"
            echo "Usage: debug <on|off|verbose>"
            echo "Debug is $ZSH_DEBUG"
    fi
}

# =========================================================
# -- zshbop_formatting ()
# =========================================================
help_zshbop[formatting]='List variables for using color'
alias formatting=zshbop_formatting
function zshbop_color () { zshbop_formatting $@; }
function zshbop_formatting () {
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

# =========================================================
# -- zshbop_custom
# =========================================================
help_zshbop[custom]='Custom zshbop configuration'
zshbop_custom () {
	_loading "Instructions on how to utilize custom zshbop configuration."
	echo " - Create a file called \$HOME/.zshbop.conf"
	echo " - You can also copy the .zshbop.conf file within this repository as a template"
}

# =========================================================
# -- zshbop_custom-load
# =========================================================
help_zshbop[custom-load]='Load zshbop custom config'
zshbop_custom-load () {
	if [[ $1 == "-q" ]]; then
        [[ -f $HOME/.zshbop.conf ]] && source $HOME/.zshbop.conf
    else
        # -- Check for $HOME/.zshbop.config, load last to allow overwritten core functions
        _log "Checking for $HOME/.zshbop.conf"
        if [[ -f $HOME/.zshbop.conf ]]; then
            ZSHBOP_CUSTOM_CFG="$HOME/.zshbop.conf"
            _log "Loaded custom zshbop config - $ZSHBOP_CUSTOM_CFG"
            source $ZSHBOP_CUSTOM_CFG
        else
            _warning "No custom zshbop config found. Type zshbop custom for more information"
        fi
    fi
}

# =========================================================
# -- zshbop_help
# =========================================================
help_zshbop[help]='zshbop help screen'
zshbop_help () {
    _debug_all
    _loading "-- zshbop ------------"
    echo ""

    # -- Print out version and other details
    zshbop_version
    echo " -- Plugin Manager: $ZSHBOP_PLUGIN_MANAGER"
    echo " -- Installation Type: $ZSHBOP_INSTALL_TYPE"
    echo " -- Installation Path: $ZSHBOP_ROOT"

    echo ""
    _loading "-- List all commands --------------"
    echo
    echo "You can type 'help' at anytime to list all available commands"
    echo
    _loading "-- core commands --------------"
    echo
    echo "These commands are available as just commands in the shell"
    echo ""
    for key in ${(kon)help_core}; do
        printf '%s\n' "  ${(r:25:)key} - ${help_core[$key]}"
    done
    echo ""

    echo ""
    _loading "-- zshbop quick --------------"
    echo ""
    echo "These commands are shortened aliases for zshbop commands"
    echo ""
    for key in ${(kon)help_zshbop_quick}; do
        printf '%s\n' "  ${(r:25:)key} - ${help_zshbop_quick[$key]}"
    done
    echo ""


    echo ""
    _loading "-- zshbop commands --------------"
    echo ""
    echo "These commands are available as zshbop <command>"
    echo ""
    for key in ${(kon)help_zshbop}; do
        printf '%s\n' "  zshbop ${(r:25:)key} - ${help_zshbop[$key]}"
    done
    echo ""
}

# =========================================================
# -- zshbop_report ($LOG_LEVEL, $TAIL_LINES)
# =========================================================
help_zshbop[report]='Print out errors and warnings'
function zshbop_report () {
    # -- Check if calling from zshbop report or zshbop_report
    if [[ $1 == "report" ]]; then
        shift
    fi        
    local LOG_LEVEL="$1"
    local SHOW_LEVEL=("ERROR" "WARNING" "ALERT")
    local TAIL_LINES=""
    local ZSHBOP_REPORT=""
    local LOG_GREP=""

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
    for LOG in ${SHOW_LEVEL[@]}; do
        # -- Only print when running zshbop_reports directly.
        if [[ $LOG_LEVEL != "faults" ]]; then
            _loading2 "-- $LOG ------------"
            _loading3 "Last $TAIL_LINES $LOG from - grep "\^\[${LOG}\]" $ZB_LOG"
            LOG_GREP+="$(grep "^\[$LOG\]" $ZB_LOG | tail -n $TAIL_LINES)"
            [[ -n $ZSHBOP_REPORT ]] && ZSHBOP_REPORT+="$LOG_GREP\n"
        else            
            ZSHBOP_REPORT+="$(grep "^\[$LOG\]" $ZB_LOG | tail -n $TAIL_LINES)"
            [[ -n $ZSHBOP_REPORT ]] && ZSHBOP_REPORT+="$LOG_GREP\n"
        fi        
    done
    echo "$ZSHBOP_REPORT" | tr -s '\n'
}

# ==============================================
# -- system_check - check usualy system stuff
# ==============================================
help_zshbop[check-system]='Print out errors and warnings'
function zshbop_check-system () {
	# -- start
	_debug_all

    # -- CPU
    _debugf "Checking CPU"
    [[ $(cpu) == "0" ]] && echo "$(_loading3 $(cpu))"

    # -- MEM
    _debugf "Checking memory"
    [[ $(mem) == "0" ]] && echo "$(_loading3 $(mem))"

    # -- network interfaces
    _debugf "Network interfaces"
    INTERFACES="$(interfaces)"
    _loading3 "Network: $INTERFACES"

	# -- check disk space
	_debugf "Checking disk space on $MACHINE_OS"
    _loading3 "$(check-diskspace)"

    #TODO block devices needs to be compacted.
	# -- check block devices
    #_debugf "Checking block devices"
    #_loading3 "Block Devices: $(check_blockdevices)"
    
}

# =========================================================
# -- zshbop_check
# =========================================================
help_zshbop[check]='Check environment for installed software and tools'
function zshbop_check () {
    _log "${funcstack[1]}:start"
    _loading "Checking environment"
    _loading3 "Checking if required tools are installed"
    for i in $REQUIRED_SOFTWARE; do
        _cmd_exists $i
        if [[ $? == "0" ]]; then
                echo "$i is $bg[green]$fg[white] INSTALLED. $reset_color"
        else
                echo "$i is $bg[red]$fg[white] MISSING. $reset_color"
        fi
    done

    _loading3 "Checking for default tools"
    for i in $DEFAULT_TOOLS; do
        _cmd_exists $i
        if [[ $? == "0" ]]; then
                echo "$i is $bg[green]$fg[white] INSTALLED. $reset_color"
        else
                echo "$i is $bg[red]$fg[white] MISSING. $reset_color"
        fi
    done

    _loading2 "Checking for extra tools"
    for i in $EXTRA_TOOLS; do
    _cmd_exists $i
    if [[ $? == "0" ]]; then
                    echo "$i is $bg[green]$fg[white] INSTALLED. $reset_color"
            else
                    echo "$i is $bg[red]$fg[white] MISSING. $reset_color"
    fi
    done
    _loading "Run zshbop install-env to install above tools"
    _log "${funcstack[1]}:end"
}

# =========================================================
# -- zshbop_install-env
# =========================================================
help_zshbop[install-env]='Install Recommended Tools and Software'
fucntion zshbop_install-env () {
    _log "${funcstack[1]}:start"
    _zshbop_install-env-collect () {
        local PKG_TYPE="$1" PACKAGES=()
        for i in ${(P)PKG_TYPE}; do            
            _require_pkg $i 0
            [[ $? -ge 1 ]] && PACKAGES+=("$i")
        done
        echo "$PACKAGES"
    }

    local PKG_TO_INSTALL=()
    _loading2 "Required tools and software"
    RS_INSTALL=($(_zshbop_install-env-collect ZB_REQUIRED_PACKAGES))
    if [[ -n $RS_INSTALL ]]; then
        _loading3 "Required Packages to install - $RS_INSTALL"
        read -q "RS_REPLY?Proceed with required packages install? [y/n] "
        echo ""
        if [[ $RS_REPLY =~ ^[Yy]$ ]]; then
            PKG_TO_INSTALL=("$RS_INSTALL")
        fi
    else
        _success "No required packages to install"        
    fi    
    echo ""

    _loading2 "Optional tools and software"
    OS_INSTALL=($(_zshbop_install-env-collect ZB_OPTIONAL_PACKAGES))
    if [[ -n $OS_INSTALL ]]; then
        _loading3 "Optional Packages to install - $OS_INSTALL"
        read -q "OS_REPLY?Proceed with optional packages install? [y/n] "
        echo ""
        if [[ $OS_REPLY =~ ^[Yy]$ ]]; then
            PKG_TO_INSTALL=("$OS_INSTALL")
        fi
    else
        _success "No optional packages to install"
    fi
    echo ""

    _loading2 "Extra tools and software"
    ES_INSTALL=($(_zshbop_install-env-collect ZB_EXTRA_PACKAGES))
    if [[ -n $ES_INSTALL ]]; then
        _loading3 "Extra Packages to install - $ES_INSTALL"
        read -q "ES_REPLY?Proceed with extra packages install? [y/n] "
        echo ""
        if [[ $ES_REPLY =~ ^[Yy]$ ]]; then
            PKG_TO_INSTALL=("$ES_INSTALL")
        fi
    else
        _success "No extra packages to install"
    fi

    if [[ -n $PKG_TO_INSTALL ]]; then
        _loading "List of packages to install"
        echo "${PKG_TO_INSTALL[@]}"
        echo ""
        read -q "REPLY?Proceed with install? [y/n] "
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            _loading3 "Installing - $PKG_TO_INSTALL"
            _require_pkg $PKG_TO_INSTALL
        else
            _loading3 "Not installing - $PKG_TO_INSTALL"
        fi
    else
        _success "No packages to install"
    fi

    
    # Install Binaries
    _loading "Installing Binaries"
    echo "Imcomplete, install manually"
    echo "$ZB_BINARIES"

    
    _log "${funcstack[1]}:stop"
}



# =========================================================
# -- zshbop_cleanup
# =========================================================
help_zshbop[cleanup]='Cleanup old things'
function zshbop_cleanup () {
    local QUEIT=${1:=0}
    _log "${funcstack[1]}:start"
    # -- older .zshrc
    OLD_ZSHRC_MD5SUM=(
        "09fcdc31ca648bb15f7bb7ff90d0539a"
        "256bb9511533e9697f639821ba63adb9"
        "46c094ff2b56af2af23c5b848d46f997"
        "3ce94ed5c5c5fe671a5f0474468d5dd3"
    )
    
    if [[ $QUEIT == 0 ]]; then
        _loading "ZSH Cleanup"
    else
        _log "Checking for old .zshrc against $ZSHRC_MD5SUM"
        if [[ -f $HOME/.zshrc ]]; then
            ZSHRC_MD5SUM="$(md5sum $HOME/.zshrc | awk {' print $1'})"
            _log "Found $HOME/.zshrc md5sum:$ZSHRC_MD5SUM"
            for i in $OLD_ZSHRC_MD5SUM; do
                _log "CUR:$ZSHRC_MD5SUM vs OLD:$i"
                if [[ $i == $ZSHRC_MD5SUM ]]; then
                    _alert "ZSH Cleanup - md5sum matched - Removing old .zshrc"
                    rm $HOME/.zshrc
                    echo "source $ZSHBOP_ROOT/zshbop.zsh" > $HOME/.zshrc
                else
                    _log "md5sum did not match"
                fi
            done
        else
            _log "No .zshrc found"
        fi
    fi
}

# =========================================================
# -- zshbop_issue
# =========================================================
help_zshbop[issue]='Create zshbop issue on Github, must have gh installed and configured'
function zshbop_issue () {
    local ISSUE_TITLE ISSUE_BODY
    _log "${funcstack[1]}:start"
    _loading "Creating zshbop issue on Github"
    _cmd_exists "gh"
    if [[ $? == "0" ]]; then
        _loading2 "Creating issue on github for jordantrizz/zshbop"
        # Ask for title, enter will accept input
        echo -n "Title (press Enter when done): "
        read ISSUE_TITLE

        # Ask for the body
        echo "Enter body (type >> on a new line to finish):"
        body=""
        while IFS= read -r line; do
            # Check for the end character/string
            if [[ "$line" == ">>" ]]; then
                break
            fi
            # Append the line to the body
            ISSUE_BODY+="$line\n"
        done

        # Print out and ask to create issue
        echo "===================================================================================================="
        echo "Title: $ISSUE_TITLE"
        echo "--------------------"
        echo "Body:"
        echo "$ISSUE_BODY"
        echo "===================================================================================================="
        echo ""
        read -q "REPLY?Create issue? [y/n] "
        echo ""

        # Create issue
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            _loading2 "Creating issue"
            gh issue create --repo jordantrizz/zshbop --title "$ISSUE_TITLE" --body "$ISSUE_BODY"
        else
            _loading2 "Not creating issue"
        fi
    else
        _error "gh not installed"
    fi
}

# =========================================================
# -- zshbop_plugins
# =========================================================
help_zshbop[plugins]='List plugins'
function zshbop_plugins () {
    _loading "Listing plugins"
    _loading "OMZ Plugins:"
    # Replace space with new line every 8 words
    echo $OMZ_PLUGINS | tr ' ' '\n' | sort | awk '{printf "%s%s", $0, (NR%8==0 ? "\n" : " ")}'
    echo ""
    _loading "Antigen Plugins:"
    cat "${ZBR}/.zsh_plugins.txt"
}

# =========================================================
# -- zshbop_setup
# =========================================================
help_zshbop[setup]='Setup zshbop, run first'
function zshbop_setup () {
    _log "${funcstack[1]}:start"
    _loading "Setting up zshbop"
    _loading2 "Checking for required software"
    zshbop_check

    _loading2 "Checking for nix"
    _cmd_exists "nix"
    if [[ $? == "0" ]]; then
        _loading2 "Nix is installed"
    else
        _loading2 "Nix is not installed.."
    fi
}

# =========================================================
# -- zshbop_variables
# =========================================================
help_zshbop[variables]='List zshbop internal variables'
function zshbop_variables () {
    _loading "ZSHBOP Variables"
    echo "ZSHBOP_ROOT: $ZSHBOP_ROOT"
    echo "ZSHBOP_VERSION: $ZSHBOP_VERSION"
    echo "ZSHBOP_BRANCH: $ZSHBOP_BRANCH"
    echo "ZSHBOP_COMMIT: $ZSHBOP_COMMIT"
    echo "ZSHBOP_INSTALL_TYPE: $ZSHBOP_INSTALL_TYPE"
    echo "ZSHBOP_PLUGIN_MANAGER: $ZSHBOP_PLUGIN_MANAGER"
    echo "ZSHBOP_UPDATE_GIT: $ZSHBOP_UPDATE_GIT"
    echo "ZSHBOP_CUSTOM_CFG: $ZSHBOP_CUSTOM_CFG"
    echo "ZSHBOP_RELOAD: $ZSHBOP_RELOAD"    
}

# =========================================================
# =========================================================
# =========================================================
# =========================================================

# =========================================================
# -- Always Last
# =========================================================

function zshbop () {
	_debug_all
    if [[ -z $1 ]]; then
		zshbop_help | less
    elif [[ $1 == "help" ]]; then
		zshbop_help | less
    elif [[ -n $1 ]]; then
		_debugf "-- Running zshbop $1"
        zshbop_cmd=(zshbop_${1})
        if [[ -n ${functions[$zshbop_cmd]} ]]; then
            $zshbop_cmd $@
        else
            echo "Function $1 does not exist."
        fi
    fi
}

# =========================================================
# -- zshbop_log
# =========================================================
help_zshbop[log]='Print out log'
function zshbop_log () {
    _log "${funcstack[1]}:start"
    _loading "Printing out log"
    cat $ZB_LOG
}

# =========================================================
# -- zshbop_internal
# =========================================================
help_zshbop[internal]='List internal functions'
function zshbop_internal () {
    _loading "Internal Functions"
    # Walk help_int
    for key in ${(kon)help_int}; do
        printf '%s\n' "  ${(r:25:)key} - ${help_int[$key]}"
    done
}