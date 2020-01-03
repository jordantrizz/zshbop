#-- When in doubt.
#- Command Type - type (command) eg type rm
#- List functions - print -l ${(ok)functions}

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
export PATH=$PATH:$HOME/bin:/usr/local/bin:$ZSH_ROOT
export PATH=$PATH:.local/bin
export TERM="xterm-256color"
export LANG="C.UTF-8"
export ZSH_CUSTOM="$ZSH_ROOT/custom"

#- Set umask
umask 022

#- Include functions file
source $ZSH_ROOT/functions.zsh
init 
