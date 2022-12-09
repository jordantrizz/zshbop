#!/usr/bin/env zsh
# ------------------------
# -- zshbop functions file
# -- This file contains all the required functions for the main .zshrc script.
# -------------------------
echo "\e[43;30m * Loading ${0:a} \e[0m"

# ------------
# -- Variables
# ------------

# -- zsh sepcific
export ZDOTDIR="${HOME}" # -- Set the ZDOTDIR to $HOME this fixes system wide installs not being able to generate .zwc files for caching

# -- zshbop specific
export SCRIPT_NAME="zshbop" # -- Current zshbop branch
export SCRIPT_DIR=${0:a:h} # -- Current working directory
export ZSHBOP_CACHE_DIR="${HOME}/.zshbop_cache"
export ZSHBOP_PLUGIN_MANAGER="init_antidote"
export ZSHBOP_VERSION=$(<$ZSHBOP_ROOT/version) # -- Current version installed
export ZSH_ROOT="${ZSHBOP_ROOT}" # -- Converting from ZSH_ROOT to ZSHBOP_ROOT
export ZBR="${ZSHBOP_ROOT}" # -- Short hand $ZSHBOP_ROOT
export KB="${ZSHBOP_ROOT}/kb"

# -- zshbop git
export ZSHBOP_BRANCH=$(git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT rev-parse --abbrev-ref HEAD) # -- current branch
export ZSHBOP_COMMIT=$(git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT rev-parse HEAD) # -- current commit
export ZSHBOP_REPO="jordantrizz/zshbop" # -- Github repository
export ZSHBOP_MIGRATE_PATHS=("/usr/local/sbin/zsh" "$HOME/zsh" "$HOME/git/zsh") # -- Previous zsbop paths

# -- zshbop md5sum
export ZSHBOP_MD5="46c094ff2b56af2af23c5b848d46f997" # -- the md5 of .zshrc
export ZSHBOP_HOME_MD5=$(md5sum $HOME/.zshrc | awk {' print $1 '}) # -- Current .zshrc MD5 in $HOME
export ZSHBOP_INSTALL_MD5=$(md5sum $ZSHBOP_ROOT/.zshrc | awk {' print $1 '}) # -- Current .zshrc MD5 in $ZSHBOPROOT

# -- Associative Arrays
typeset -gA help_custom # -- Set help_custom for custom help files

# -- Default tools.
default_tools=('mosh' 'traceroute' 'mtr' 'pwgen' 'tree' 'ncdu' 'fpart' 'whois' 'pwgen' 'python3-pip' 'joe' )
default_tools+=('keychain' 'dnsutils' 'whois' 'gh' 'php-cli' 'telnet' 'lynx' 'jq' 'shellcheck' 'sudo' 'fzf')
extra_tools=('pip' 'npm' 'golang-go' 'net-tools')
pip_install=('ngxtop' 'apt-select' 'semgrep')

# -- Take $EDITOR run it through alias and strip it down
EDITOR_RUN=${${$(alias $EDITOR)#joe=\'}%\'}

# -- fzf keybindings, enable if fzf is available @@ISSUE
#[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"
####-- diff-so-fancy
# git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"

# ------------------------
# -- Environment variables
# ------------------------

# - Set umask
umask 022
export TERM="xterm-256color"
export LANG="C.UTF-8"
export HISTSIZE=5000
export PAGER='less -Q -j16'
export EDITOR='joe'
export BLOCKSIZE='K'
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export TERM="xterm-256color"
export LANG="C.UTF-8"
export bgnotify_threshold='6' # https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/bgnotify # -- ohmyzsh specific environment variables
export SSHK="$HOME/.ssh"
export TMP="$HOME/tmp"

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

# ---------------------
# -- Internal Functions
# ---------------------

# -- Different colored messages
_echo () { echo "$@" }
_error () { echo  "$fg[red] * $@ $reset_color" }
_warning () { echo "$fg[yellow] * $@ $reset_color" }
_success () { echo "$fg[green] * $@ $reset_color" }
_notice () { echo "$fg[magenta] * $@ $reset_color" }

# -- Banners
_banner_red () { echo "$bg[red]$fg[white] $@ $reset_color" }
_banner_green () { echo "$bg[green]$fg[white] $@ $reset_color" }
_banner_yellow () { echo "$bg[yellow]$fg[black] $@ $reset_color" }
_banner_grey () { echo "$bg[bright-grey]$fg[black] $@ $reset_color" }
_loading () { echo "$bg[yellow]$fg[black] * $@ $reset_color" }
_loading2 () { echo "  $bg[bright-grey]$fg[black] $@ $reset_color" }
alias _loading_grey=_loading2

# -- Text Colors
_grey () { echo "$bg[bright-gray]$fg[black] $@ $reset_color" }

# ------------
# -- Debugging
# ------------
ZSH_DEBUG="0"

# -- zshbop debugging
if [ -f $ZSHBOP_ROOT/.debug ]; then
        export ZSH_DEBUG=1
elif [ ! -f $ZSHBOP_ROOT/.debug ]; then
        export ZSH_DEBUG=0
fi

# -- _debug
_debug () {
    if [[ $ZSH_DEBUG == 1 ]]; then
        echo "$fg[cyan]** DEBUG: $@$reset_color";
    fi
}

# -- _debug_all
_debug_all () {
        _debug "--------------------------"
        _debug "arguments - $@"
        _debug "funcstack - $funcstack"
        _debug "ZSH_ARGZERO - $ZSH_ARGZERO"
        _debug "SCRIPT_DIR - $SCRIPT_DIR"
        _debug "--------------------------"
}

# -----------------
# -- Core Functions
# -----------------

#-- Check to see if command exists and then return true or false
_require_pkg () {
        _debug_function
        _debug "Running _requires_pkg on $1"
        _debug "array: ${(P)${array_name}}"
        
                local array_name=$1
        PKG=""
        
        for PKG in ${(P)${array_name}}; do
		if [[ $(dpkg-query -W -f='${Status}' nano 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
                        if [[ $ZSH_DEBUG == 1 ]]; then
                                _debug "$PKG is installed";
                                REQUIRES_PKG=0
                        fi
                else
                        if [[ $ZSH_DEBUG == 1 ]]; then
                                _debug "$PKG not installed";
                        fi
                        echo "$PKG not installed, installing"
                        sudo apt-get install $PKG
                        REQUIRES_PKG=1
                fi
        done
        
}
_requires_cmd () {
	_debug_function
	_debug "Running _requires on $1"
	_debug "array: ${(P)${array_name}}"

	local array_name=$1
	CMD=""
	
	for CMD in ${(P)${array_name}}; do
	        if (( $+commands[$CMD] )); then
			_debug $(which $CMD)
	              	if [[ $ZSH_DEBUG == 1 ]]; then
	                        _debug "$CMD is installed";
	                        REQUIRES_CMD=0
        	        fi
	        else
	                if [[ $ZSH_DEBUG == 1 ]]; then
                	        _debug "$CMD not installed";
        	        fi
	                echo "$CMD not installed"
	                REQUIRES_CMD=1
	        fi
        done
}

# -- _cexists -- Returns 0 if command exists or 1 if command doesn't exist
_cexists () {
	unset CMD_EXISTS CMD CMD_PATH
	CMD="$1"
	
	# Check if command exists
	CE_PATH=$(which $CMD)
	CE_EXIT_CODE=$?
    if [[ $CE_EXIT_CODE == "0" ]]; then
		CMD_PATH=$(which $CMD)
		_debug "CMD_PATH: $CMD_PATH"
        if [[ $ZSH_DEBUG == 1 ]]; then
        	_debug "$CMD is installed";
        fi
        	CMD_EXISTS="0"
    else
    	if [[ $ZSH_DEBUG == 1 ]]; then
        	_debug "$CMD not installed";
        fi
        	CMD_EXISTS="1"
    fi
    
    # Check if alias exists
    return $CMD_EXISTS
}

_checkroot () {
        _debug_function
	if [[ $EUID -ne 0 ]]; then
		_error "Requires root...exiting."
	return
	fi
}

# -- _if_marray - if in array.
# -- _if_marray "$NEEDLE" HAYSTACK 
# -- must use quotes, second argument is array without $
_if_marray () {
	_debug_function
        MARRAY_VALID=1
        _debug "$funcstack[1] - find value = $1 in array = $2"
        for value in ${(k)${(P)2[@]}}; do
                _debug "$funcstack[2] - array=$2 \$value = $value"
                if [[ $value == "$1" ]]; then
                        _debug "$funcstack[1] - array $2 does contain $1"
                        MARRAY_VALID="0"
                else
                        _debug "$funcstack[1] - array $2 doesn't contain $1"
                fi
        done
        _debug "MARRAY_VALID = $MARRAY_VALID"
        if [[ MARRAY_VALID == "1" ]]; return 0
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
typeset -gA help_zshbop 

# -- cc - clear cache for various tools
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

# -- rld / reload
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

# -- zshbop_startup
help_zshbop[startup]='Run zshbop startup'
zshbop_startup () {
	_debug_function
	init_motd
}

# -- branch
help_zshbop[branch]='Run main or dev branch of zshbop'
zshbop_branch  () {
        _debug_function
        if [ "$2" = "dev" ]; then
                echo "	-- Switching to dev branch"
                git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT checkout dev
        elif [ "$2" = "main" ]; then
                echo "	-- Switching to main branch"
                 git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT checkout main
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

# -- zshbop_pervious-version-check
help_zshbop[previous-version-check]='Checking if \$HOME/.zshrc is pre v1.1.3 and replacing.'
zshbop_previous-version-check () {
        _debug_function

        # Replacing .zshrc previous to v1.1.2 256bb9511533e9697f639821ba63adb9
        _debug " -- Current $HOME/.zshrc md5 is - $ZSHBOP_HOME_MD5"
        _debug " -- zshbop .zshrc md5 is - $ZSHBOP_MD5"
        if [[ "$ZSHBOP_HOME_MD5" != "$ZSHBOP_MD5" ]]; then
                _error "-- Found old .zshrc"
                _notice "-- Replacing $HOME/.zshrc"
                cp $ZSHBOP_ROOT/.zshrc $HOME/.zshrc
        else
        	_debug " -- No need to fix .zshrc"
        fi
}

# -- migrate-check
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

# -- migrate
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

# -- zshbop_version
help_zshbop[version]='Get version information'
zshbop_version () {
        _debug_function
        _loading "zshbop Version"
        echo "Version: $fg[green]$ZSHBOP_VERSION/$ZSHBOP_BRANCH/$ZSHBOP_COMMIT$reset_color"
        echo "Install .zshrc MD5: $fg[green]$ZSHBOP_HOME_MD5$reset_color --"
}

# -- zshbop_version_check
help_zshbop[version-check]='Check version'
zshbop_version-check () {
  _debug_function
	zshbop_version
	_loading "zshbop Version Check"
    echo "-- Script: $fg[green]$ZSHBOP_MD5$reset_color"
    echo "-- \$ZSHBOP/.zshrc: $fg[green]$ZSHBOP_INSTALL_MD5$reset_color"
    echo "-- \$HOME/.zshrc MD5: $fg[green]$ZSHBOP_HOME_MD5$reset_color"
        
    _loading2 "Checking if $HOME/.zshrc is the same as $ZSHBOP/.zshrc"
    if [[ $ZSHBOP_HOME_MD5 == $ZSHBOP_INSTALL_MD5 ]]; then
      _success "  \$HOME/.zshrc and  \$ZSHBOP/.zshrc are the same."
    else
      _error "  \$HOME/.zshrc and \$ZSHBOP/.zshrc are the different."
    fi
}

# -- zshbop_debug
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

# -- zshbop_color
help_zshbop[colors]='List variables for using color'
zshbop_colors () {
        _debug_function
        echo "-- Color names"
        for k in ${color}; do
	   print -- key: $k
	done

        echo "-- How to use color"
        echo "  Foreground \$fg[blue] \$fg[red] \$fg[yellow] \$fg[green]"
        echo "  Background \$fg[blue] \$fg[red] \$fg[yellow] \$fg[green]"
        echo "  Reset Color: \$reset_color"

        echo "-- Color Options"
        _banner_red "  -- _banner_red"
        _banner_green "  -- _banner_green"
        _banner_yellow "  -- _banner_yellow"
        _error "  -- _error"
        _warning "  -- _warning"
        _success "  -- _success"
        _notice "  -- _notice"
}

# -- zshbop_custom
help_zshbop[custom]='Custom zshbop configuration'
zshbop_custom () {
	_banner_green "Instructions on how to utilize custom zshbop configuration."
	echo " - Create a file called .zshbop.custom in your /$HOME directory"
	echo " - Done!"
	echo " - You can also copy the .zshbop.custom file within this repository as a template"
}

# -- zshbop_load_custom
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

# -- check if nala is installed
check_nala () {
        _debug_function
        _debug "Checking if nala is installed"
        _cexists nala
        if [[ $? == "0" ]]; then
	        _debug "nala installed - running zsh completions"
	        source /usr/share/bash-completion/completions/nala
        fi
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