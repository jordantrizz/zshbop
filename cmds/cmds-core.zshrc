# --
# Core commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_core

# - Don't know what cmd was for?
cmd () { }; help_core[cmd]='broken and needs to be fixed'

# -- rld - rld zshbop
help_core[rld]='Reload $SCRIPT'
rld () { source $ZSH_ROOT/init.zshrc;init }

# -- cc - clear cache for various tools
help_core[cc]='Clear cache for antigen + more'
cc () {
        antigen reset; rm ~/.zshrc.zwc
}

# -- Knowledge Base - A built in knowledge base.
help_core[kb]='knowledge base'
kb () {
        if _cexists mdv; then mdv_reader=mdv; else mdv_reader=cat fi

        if [[ -a $ZSH_ROOT/kb/$1.md ]]; then
                echo "Opening $ZSH_ROOT/kb/$1.md"
                $mdv_reader $ZSH_ROOT/kb/$1.md
        else
                ls -l $ZSH_ROOT/kb
        fi
        if [[ $mdv_reader == cat ]]; then
                echo "\n\n"
                echo "---------------------------------------"
                echo "mdv not avaialble failing back to cat"
                echo "you should install mdv, pip install mdv"
        fi
}