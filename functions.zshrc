# --------------
# -- Functions
# --------------
# This file contains all the required functions for the main .zshrc script.

# -----------------------
# -- One line functions
# -----------------------

# -- Core functions
_echo () { echo "$@" }
_debug () { if [[ $ZSH_DEBUG == 1 ]]; then echo "** DEBUG: $@"; fi }

# -- General functions
cmd () { } # describe all aliases (notworking)
rld () { init }
cc () { antigen reset; rm ~/.zshrc.zwc } # clear cache

# -- Knowledge Base
# A built in knowledge base.
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

###-- Check Environment
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
installenv () {
        echo "---------------------------"
        echo "Installing default tools.."
        echo "---------------------------"
	sudo apt install $default_tools
        echo "---------------------------"
        echo "Installing extra tools.."
        echo "---------------------------"
        sudo apt install $extra_tools
	echo "---------------------------"
	echo "Manual installs"
	echo "---------------------------"
	echo "gh - installed separately, run github-cli"
	echo "gnomon - via npm"
	echo "lsd - https://github.com/Peltoche/lsd"
}

#### -- Install Environment
# Custom install of some much needed tools!
customenv () {
	# Need to add in check for pip3
	pip3 install -U checkdmarc
}

#### -- Update
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

#### -- Copy Windows Terminal Config
cp_wtconfig () {
	cp /mnt/c/Users/$USER/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/profiles.json  $ZSH_ROOT/windows_terminal.json
}

#### -- Configure git
git_config () {
	vared -p "Name? " -c GIT_NAME
	vared -p "Email? " -c GIT_EMAIL
	git config --global user.email $GIT_EMAIL
	git config --global user.name $GIT_NAME
	git config --global --get user.email
	git config --global --get user.name
}

# ---- Add SSH Key
addsshkey () {
	echo "-- Adding $1 to keychain"
	keychain -q --eval --agents ssh $HOME/.ssh/$1
}
