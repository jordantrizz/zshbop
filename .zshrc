#-- When in doubt.
#- Command Type - type (command) eg type rm
#- List functions - print -l ${(ok)functions}

#- We use $ZSH_ROOT to know our working directory.
if [ -z "$ZSH_ROOT" ]; then
      echo "-- \$ZSH_ROOT empty so using \$HOME/zsh"
      export ZSH_ROOT=$HOME/zsh
fi

#- If you come from bash you might have to change your $PATH.
export PATH=$PATH:$HOME/bin:/usr/local/bin:$ZSH_ROOT
export PATH=$PATH:.local/bin
export TERM="xterm-256color"
export LANG="C.UTF-8"
export ZSH_CUSTOM="$ZSH_ROOT/custom"

#- Include functions file
source $ZSH_ROOT/functions.zsh
init_antigen
init_defaults
sshkeys