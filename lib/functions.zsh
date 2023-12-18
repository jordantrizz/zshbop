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
# zbu
help_zshbop_quick[zbu]='Update zshbop'
alias zbu="zshbop_update"
# zbr
help_zshbop_quick[zbr]='Reload zshbop'
alias zbr="zshbop_reload"
# zbur
help_zshbop_quick[zbur]='Update and reload zshbop'
alias zbur="zshbop_update;zshbop_reload"
# zbqr
help_zshbop_quick[zbqr]='Quick reload zshbop'
alias zbqr="zshbop_reload -q"
# zbuqr
help_zshbop_quick[zbuqr]='Update and quick reload zshbop'
alias zbuqr="zshbop_update;zshbop_reload -q"

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
        export RUN_REPORT=0
        export ZSHBOP_RELOAD=1
        zshbop_cache-clear
        init_zshbop
    else
        _loading "Reloading zshbop"
        export RUN_REPORT=1
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

# =========================================================
# -- zshbop_update ()
# --
# -- Update ZSHBOP
# =========================================================
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
        [[ $? -eq "1" ]] && { _error "Failed to pull latest changes"; return 1 }
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT pull
        [[ $? -eq "1" ]] && { _error "Failed to pull latest changes"; return 1 }
    else
        git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT pull
        [[ $? -eq "1" ]] && { _error "Failed to pull latest changes"; return 1 }
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

# =========================================================
# -- zshbop_version ()
# =========================================================
help_zshbop[version]='Get version information'
zshbop_version () {
        echo "zshbop Version: ${fg[green]}${ZSHBOP_VERSION}/${fg[black]}${bg[cyan]}${ZSHBOP_BRANCH}${reset_color}/$ZSHBOP_COMMIT${RSC}"
}

# =========================================================
# -- zshbop_debug ()
# =========================================================
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
            zshbop_reload
    elif [[ $1 == "off" ]] || [[ $2 == "off" ]]; then
            echo "Turning debug off"
            _debug "Turning debug off"
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
            _debug "Turning debug verbose on"
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
            _loading2 "Loaded custom zshbop config - $ZSHBOP_CUSTOM_CFG"
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
    _loading "-- core commands --------------"
    echo ""
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
    echo "These commands are available as zshbop commands in the shell"
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
    _debug "Checking CPU"
    [[ $(cpu) == "0" ]] && echo "$(_loading3 $(cpu))"

    # -- MEM
    _debug "Checking memory"
    [[ $(mem) == "0" ]] && echo "$(_loading3 $(mem))"

    # -- network interfaces
    _debug "Network interfaces"
    INTERFACES="$(interfaces)"
    _loading3 "Network: $INTERFACES"

	# -- check disk space
	_debug "Checking disk space on $MACHINE_OS"
    _loading3 "$(check-diskspace)"

    #TODO block devices needs to be compacted.
	# -- check block devices
    #_debug "Checking block devices"
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
help_zshbop[install-env]='Install environment tools'
fucntion zshbop_install-env () {
    _log "${funcstack[1]}:start"
    _loading "Installing environment"
    _loading3 "Required tools - ${REQUIRED_SOFTWARE[@]}"
    _loading2 "Generating list of required tools that need to be insstalled"
    # -- install required tools
    for i in ${REQUIRED_SOFTWARE[@]}; do
        _cmd_exists $i
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

# -- zshbop_software - Install softare into environment.
help_zshbop[install-software]='Install software into environment'
zshbop_install-software () {
	sudo apt-get update
    _loading "Installing Software..."
    echo ""    
    _loading2 "Installing required software.."
    echo "REQUIRED_SOFTWARE: $REQUIRED_SOFTWARE"
    if read -q "Continue? (y/n)"; then
        sudo apt-get install --no-install-recommends $required_software
    else
        echo "Skipping due to press 'n'"
    fi

    _loading2 "Installing optional software"
    echo "OPTIONAL_SOFTWARE: $OPTIONAL_SOFTWARE"
    if read -q "Continue? (y/n)"; then
        sudo apt-get install --no-install-recommends $OPTIONAL_SOFTWARE
    else
        echo "Skipping due to press 'n'"
    fi

    _loading2 "Installing extra software"
    echo "EXTRA_SOFTWARE: $EXTRA_SOFTWARE"
    if read -q "Continue? (y/n)"; then
        sudo apt-get install --no-install-recommends $OPTIONAL_SOFTWARE
    else
        echo "Skipping due to press 'n'"
    fi

    #TODO FIX
    echo "---------------------------"
    echo "Manual installs"
    echo "---------------------------"
    echo " mdv       - pip install mdv"
    echo " gnomon    - via npm"
    echo " lsd       - https://github.com/Peltoche/lsd"
    echo ""
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
		_debug "-- Running zshbop $1"
        zshbop_cmd=(zshbop_${1})
        if [[ -n ${functions[$zshbop_cmd]} ]]; then
            $zshbop_cmd $@
        else
            echo "Function $1 does not exist."
        fi
    fi
}




