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

# -- kb - A built in knowledge base.
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

# -- checkenv - Check Environment for installed software
help_core[checkenv]='check environment for installed software and tools'
checkenv () {
        echo "---------------------------"
        echo "Looking for default tools.."
        echo "---------------------------"
        echo ""
        for i in $default_tools; do
                if _cexists $i; then
                        echo "$i is $BGGREEN INSTALLED. $RESET"
                else
                        echo "$i is $BGRED MISSING. $RESET"
                fi
        done
        echo "---------------------------"
        echo "Looking for default tools.."
        echo "---------------------------"
        echo ""
        for i in $extra_tools; do
        if _cexists $i; then
                echo "$i is $BGGREEN INSTALLED. $RESET"
        else
                echo "$i is $BGRED MISSING. $RESET"
        fi
        done
        echo "--------------------------------------------"
        echo "Run installenv to install above tools"
        echo "--------------------------------------------"

}

# -- installenv - Install tools into environment.
help_core[installenv]='Install tools into environment'
installenv () {
        echo "---------------------------"
        echo "Installing default tools.."
        echo "---------------------------"
        sudo apt-get update
        sudo apt install $default_tools
        echo "---------------------------"
        echo "Installing extra tools.."
        echo "---------------------------"
        sudo apt install $extra_tools
        echo "---------------------------"
        echo "Manual installs"
        echo "---------------------------"
        echo " mdv       - pip install mdv"
        echo " gnomon    - via npm"
        echo " lsd       - https://github.com/Peltoche/lsd"
        echo ""
}


# -- customenv - Install custom software into environment.
help_core[customenv]='Install custom tools into environment'
customenv () {
        # Need to add in check for pip3
        pip install -U checkdmarc
	mkdir $ZSH_ROOT/tmp
	cd $ZSH_ROOT/tmp
	git clone https://github.com/axiros/terminal_markdown_viewer.git
	pip install .
}

# -- update - Update ZSHBOP
help_core[update]='update zshbop'
update () {
        # Pull zshbop
        echo "--- Pulling zshbop updates"
        git -C $ZSH_ROOT pull

        # Update Personal ZSH
        if [ ! -z $ZSH_PERSONAL_DIR ]; then
                echo "--- Pulling Personal ZSH repo"
                git -C $ZSH_PERSONAL_DIR pull
        fi

        # Update repos
        for name in $ZSH_ROOT/repos/*
        do
                echo "-- Updating repo $name"
                git -C $name pull
        done

        # Reload scripts
        echo "--- Type rld to reload zshbop"
}

# -- check-updates - Check for zshbop updates.
check-updates () {

}
