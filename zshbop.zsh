#!/usr/bin/env zsh
# =========================================================
# -- zshbop.zsh -- zshbop main file
# -- 
# =========================================================

# ---------------------------
# -- Initilize zshbop
# ---------------------------
export ZSHBOP_ROOT=${0:a:h} # -- Current working directory
source $ZSHBOP_ROOT/lib/init.zsh

# ---------------------------
# ---- Variables
# ---------------------------

# -- autoload
autoload -Uz compinit compdef
compinit

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

# -- Associative Arrays
typeset -gA help_custom # -- Set help_custom for custom help files

# -- Required Tools
REQUIRED_SOFTWARE=('jq' 'curl' 'zsh' 'git' 'md5sum' 'sudo' 'screen' 'git' 'joe' 'dnsutils' 
    'net-tools' 'dmidecode' 'virt-what' 'wget' 'unzip' 'zip' 'python3' 'python3-pip'
    'bc' 'whois' 'telnet' 'lynx' 'traceroute' 'mtr' 'mosh' 'tree' 'ncdu' 'fpart'
    'jq' 'ethtool' 'lsblk' 'blkid' 'smartctl' 'hdparm' 'lshw' 'lspci' 'lscpu')

# -- Default tools.
DEFAULT_TOOLS=('mosh' 'traceroute' 'mtr' 'pwgen' 'tree' 'ncdu' 'fpart' 'whois' 'pwgen' 'python3-pip' 'joe' )
DEFAULT_TOOLS+=('keychain' 'dnsutils' 'whois' 'gh' 'php-cli' 'telnet' 'lynx' 'jq' 'shellcheck' 'sudo' 'fzf')
EXTRA_TOOLS=('pip' 'npm' 'golang-go' 'net-tools')
pip_install=('ngxtop' 'apt-select' 'semgrep')

# -- Take $EDITOR run it through alias and strip it down
EDITOR_RUN=${${$(alias $EDITOR)#joe=\'}%\'}

# -- fzf keybindings, enable if fzf is available @@ISSUE
#[ -f $ZSH_CUSTOM/.fzf-key-bindings.zsh ] && source $ZSH_CUSTOM/.fzf-key-bindings.zsh;echo "Enabled FZF keybindgs"
####-- diff-so-fancy
# git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"

# -- OMZ History Plugin
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data

# -- zshbop.config
if [[ -f $HOME/.zshbop.config ]]; then
	source $HOME/.zshbop.config
fi

###########################################################
###########################################################
# --- DON'T PUT ANYTHING BELOW THIS LINE ---
# -------------------------
# -- Initialize ZSHBOP
# -------------------------
STARTLOG
init_zshbop
STOPLOG