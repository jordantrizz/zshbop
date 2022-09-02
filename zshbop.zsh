#!/usr/bin/env zsh
# ------------------------
# -- zshbop file
# -------------------------

# -----------------
# -- Core functions
# -----------------
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

# -- debugging
ZSH_DEBUG="0"
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
alias _debug_function="_debug_all"

# ---------
# -- Colors
# ---------

# -- old method
# $fg[blue] $fg[red] $fg[yellow] $fg[green] $reset_color
#autoload colors
#if [[ "$terminfo[colors]" -gt 8 ]]; then
#    colors
#fi

# -- New method
source $ZSHBOP_ROOT/colors.zsh


# -----------
# -- Includes
# -----------
source $ZSHBOP_ROOT/functions.zsh # -- include functions
source $ZSHBOP_ROOT/init.zsh # -- include init
source $ZSHBOP_ROOT/aliases.zsh # -- include functions
source $ZSHBOP_ROOT/help.zsh # -- include help functions
source $ZSHBOP_ROOT/kb.zsh # -- Built in Knolwedge Base

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


# ------------
# -- Variables
# ------------

# -- zsh sepcific
ZDOTDIR=$HOME # -- Set the ZDOTDIR to $HOME this fixes system wide installs not being able to generate .zwc files for caching

# -- zsbop exports
export ZSHBOP_ZSHRC_MD5="3ce94ed5c5c5fe671a5f0474468d5dd3" # -- the md5 of .zshrc

# -- zshbop variables
SCRIPT_NAME="zshbop" # -- Current zshbop branch
SCRIPT_DIR=${0:a:h} # -- Current working directory
ZSHBOP_VERSION=$(<$ZSHBOP_ROOT/version) # -- Current version installed
ZSH_ROOT=$ZSHBOP_ROOT # -- Converting from ZSH_ROOT to ZSHBOP_ROOT
ZBR=$ZSHBOP_ROOT # -- Short hand $ZSHBOP_ROOT
ZSHBOP_BRANCH=$(git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT rev-parse --abbrev-ref HEAD) # -- current branch
ZSHBOP_COMMIT=$(git --git-dir=$ZSHBOP_ROOT/.git --work-tree=$ZSHBOP_ROOT rev-parse HEAD) # -- current commit
ZSHBOP_REPO="jordantrizz/zshbop" # -- Github repository
ZSHBOP_MIGRATE_PATHS=("/usr/local/sbin/zsh" "$HOME/zsh" "$HOME/git/zsh") # -- Previous zsbop paths
ZSHBOP_ZSHRC_HOME_MD5=$(md5sum $HOME/.zshrc | awk {' print $1 '}) # -- Current .zshrc MD5 in $HOME
ZSHBOP_ZSHRC_ZSHBOP_MD5=$(md5sum $ZSHBOP_ROOT/.zshrc | awk {' print $1 '}) # -- Current .zshrc MD5 in $ZSHBOPROOT

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

# -------------------------
# -- Check for old versions
# -------------------------
zshbop_previous-version-check
zshbop_migrate