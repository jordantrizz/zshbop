# --------------
# -- Functions
# --------------
# This file contains all the required functions for the main .zshrc script.

# -----------------------
# -- One line functions
# -----------------------

# -- placehodler for echo
_echo () { echo "$@" }

# -- debugging
_debug () { if [[ $ZSH_DEBUG == 1 ]]; then echo "** DEBUG: $@"; fi }

#-- Check to see if command exists and then return true or false
_cexists () {
        if (( $+commands[$@] )); then
                if [[ $ZSH_DEBUG == 1 ]]; then
                        _debug "$@ is installed";
                fi
                return 0
        else
                if [[ $ZSH_DEBUG == 1 ]]; then
                        _debug "$@ not installed";
                fi
                return 1
        fi
}


# -- Check Environment
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

#### -- Setup Environment
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
	echo "You can install all manual installs, via customenv"
}

#### -- Install Environment
# Custom install of some much needed tools!
help_core[customenv]='Install custom tools into environment'
customenv () {
	# Need to add in check for pip3
	pip install -U checkdmarc
	pip install mdv
}

#### -- Update
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

check-updates () {

}

#### -- List current functions available to zsh
# when in doubt print -l ${(ok)functions}
options () {
    PLUGIN_PATH="$HOME/.oh-my-zsh/plugins/"
    for plugin in $plugins; do
        _echo "\n\nPlugin: $plugin"; grep -r "^function \w*" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/()//'| tr '\n' ', '; grep -r "^alias" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/=.*//' |  tr '\n' ', '
    done
}
