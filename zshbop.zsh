#!/usr/bin/env zsh
# ------------------------
# -- zshbop file
# -------------------------

# -----------------
# -- Core functions
# -----------------
# -- Different colored messages
_echo () { echo "$@" }
_error () { echo  "$fg[red]** $@ $reset_color" }
_warning () { echo "$fg[yellow]** $@ $reset_color" }
_success () { echo "$fg[green]** $@ $reset_color" }
_notice () { echo "$fg[magenta]** $@ $reset_color" }
_banner_red () { echo "$bg[red]$fg[white]          $@          $reset_color" }
_banner_green () { echo "$bg[green]$fg[white]          $@          $reset_color" }

# -- debugging
_debug () {
	if [[ $ZSH_DEBUG == 1 ]]; then
		echo "$fg[cyan]** DEBUG: $@$reset_color";
	fi
}

_debug_all () {
        _debug "--------------------------"
        _debug "arguments - $@"
        _debug "funcstack - $funcstack"
        _debug "ZSH_ARGZERO - $ZSH_ARGZERO"
        _debug "SCRIPT_DIR - $SCRIPT_DIR"
        _debug "--------------------------"
}

_debug_function () {
	_debug "$bg[cyan]$fg[black]~~~~ function $funcstack[2] ~~~~$reset_color"
}

# -- Colors
# $fg[blue] $fg[red] $fg[yellow] $fg[green] $reset_color
autoload colors
if [[ "$terminfo[colors]" -gt 8 ]]; then
    colors
fi


# -----------
# -- Includes
# -----------
source $ZSHBOP_ROOT/functions.zsh # -- include functions
source $ZSHBOP_ROOT/init.zsh # -- include init
source $ZSHBOP_ROOT/aliases.zsh # -- include functions
source $ZSHBOP_ROOT/help.zsh # -- include help functions

# -------------------------
# -- Check for old versions
# -------------------------
zshbop_previous-version-check
zshbop_migrate

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


# ------------
# -- Variables
# ------------

# -- zsh sepcific
ZDOTDIR=$HOME # -- Set the ZDOTDIR to $HOME this fixes system wide installs not being able to generate .zwc files for caching

# -- zsbop exports
export ZSHBOP_ZSHRC_MD5="cd0a568e262f60df01c0f45b9cd6b5fe" # -- the md5 of .zshrc

# -- zshbop variables
SCRIPT_NAME="zshbop" # -- Current zshbop branch
SCRIPT_DIR=${0:a:h} # -- Current working directory
ZSHBOP_VERSION=$(<$ZSHBOP_ROOT/version) # -- Current version installed
ZSH_ROOT=$ZSHBOP_ROOT # -- Converting from ZSH_ROOT to ZSHBOP_ROOT
ZBR=$ZSHBOP_ROOT # -- Short hand $ZSHBOP_ROOT
ZSHBOP_BRANCH=$(git -C $ZSHBOP_ROOT rev-parse --abbrev-ref HEAD) # -- current branch
ZSHBOP_COMMIT=$(git -C $ZSHBOP_ROOT rev-parse HEAD) # -- current commit
ZSHBOP_REPO="jordantrizz/zshbop" # -- Github repository
ZSHBOP_MIGRATE_PATHS=("/usr/local/sbin/zsh" "$HOME/zsh" "$HOME/git/zsh") # -- Previous zsbop paths
ZSHBOP_CURRENT_ZSHRC_MD5=$(md5sum $HOME/.zshrc | awk {' print $1 '}) # -- Current .zshrc MD5

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


# ----------
# -- Aliases
# ----------
alias update="zshbop_update"
alias rld="zshbop_reload"
alias zb=zshbop

# -------------------
# -- zshbop debugging
# -------------------

if [ -f $ZSHBOP_ROOT/.debug ]; then
        export ZSH_DEBUG=1
elif [ ! -f $ZSHBOP_ROOT/.debug ]; then
        export ZSH_DEBUG=0
fi

# -------
# -- Main
# -------

# -- If you need to set specific overrides, then create a file in $HOME/.zshbop and add overrides.
if [[ -f $HOME/.zshbop ]]; then
	source $HOME/.zshbop
fi