#-- When in doubt.
#- Command Type - type (command) eg type rm
#- List functions - print -l ${(ok)functions}

#- Set the ZDOTDIR to $HOME this fixes system wide installs not being able to generate .zwc files for caching
$ZDOTDIR=$HOME

# Need to refactor this at somepoint
JTZSH_ROOT=$ZSH_ROOT

#- Include functions file
source $ZSH_ROOT/functions.zshrc

#- Are we debugging?
if [ -f $ZSH_ROOT/.debug ]; then
	export ZSH_DEBUG=1
fi

#- We use $ZSH_ROOT to know our working directory.
if [ -z "$ZSH_ROOT" ]; then
	_debug "-- \$ZSH_ROOT empty so using \$HOME/zsh"
	export ZSH_ROOT=$HOME/zsh
else
	_debug "-- \$ZSH_ROOT not empty so using $ZSH_ROOT"
fi

#- If you come from bash you might have to change your $PATH.
export TERM="xterm-256color"
export LANG="C.UTF-8"
export ZSH_CUSTOM="$ZSH_ROOT/custom"

#- Set umask
umask 022

#- Let's start init
init 
