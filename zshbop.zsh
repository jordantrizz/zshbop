#!/usr/bin/env zsh
# ------------------------
# -- zshbop file
# -------------------------

# ------------
# -- Variables
# ------------

# -- autoload
autoload -Uz compinit 
autoload -Uz compdef

# -- Help arrays
typeset -gA help_files
typeset -gA help_files_description
typeset -gA help_corefunc
typeset -gA help_zshbop

# -- System settings
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
export ZSHBOP_LATEST_MD5="46c094ff2b56af2af23c5b848d46f997" # -- the md5 of .zshrc
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

###########################################################

# ---------------
# -- Source files
# ---------------
source ${ZSHBOP_ROOT}/colors.zsh # -- colors first!
source ${ZSHBOP_ROOT}/functions-core.zsh #--
source ${ZSHBOP_ROOT}/functions.zsh # -- 
source ${ZSHBOP_ROOT}/init.zsh # -- include init
source ${ZSHBOP_ROOT}/aliases.zsh # -- include functions
source ${ZSHBOP_ROOT}/help.zsh # -- include help functions
source ${ZSHBOP_ROOT}/kb.zsh # -- Built in Knolwedge Base

############################################################

# -------
# -- Main
# -------

# -- If you need to set specific configuration settings then create $HOME/.zshbop.config and look at zshbop.config.example
if [[ -f $HOME/.zshbop.config ]]; then
	source $HOME/.zshbop.config
fi

# -------------------------
# -- Check for old versions
# -------------------------
zshbop_previous-version-check
zshbop_migrate