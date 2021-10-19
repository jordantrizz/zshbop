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
rld () { source $ZSH_ROOT/.zshrc }
cc () { antigen reset; rm ~/.zshrc.zwc } # clear cache

#### -- help
help () {
        echo "General help for $SCRIPT_NAME"
        echo " ------------------------------ "
        echo " kb - Knowledge Base"
        echo " help - this command"
        echo " rld - reload this script"
        echo " cc - clear antigen cache"
        echo " update - update this script"
        echo " options - list all zsh functions"
}

startup_motd () {
echo "---- "

}

#### -- kb
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
check_environment () {
	echo "------------------------"
	for i in $default_tools; do
		if _cexists $i; then
			echo "$i is $BGGREEN INSTALLED. $RESET"
		else
			echo "$i is $BGRED MISSING. $RESET"
		fi
	done
	echo "--------------------------------------------"
	echo "Run setup_environment to install above tools"
	echo "--------------------------------------------"
}

#### -- Setup Environment
setup-environment () {
	sudo apt install $default_tools
	echo "gh - installed separately, run github-cli"
	echo "install_environment - install more tools"
	#keychain mosh traceroute mtr keychain pwgen tree ncdu fpart whois pwgen
	#sudo apt install python-pip npm # Skipping python dependencies
	#sudo pip install apt-select # Skipping python dependencies
       	#sudo npm install -g gnomon # Skipping node dependencies
}

#### -- Install Environment
# Custom install of some much needed tools!
install-environment () {
	# Need to add in check for pip3
	pip3 install -U checkdmarc
}

#### -- Update
update () {
        git -C $ZSH_ROOT pull
	# Updated sub-modules
	if [[ $1 == "-f" ]]; then
	        git -C $ZSH_ROOT pull --recurse-submodules
	        git -C $ZSH_ROOT submodule update --init --recursive
        	git -C $ZSH_ROOT submodule update --recursive --remote
        	git -C $ZSH_ROOT submodule foreach git pull origin master
	fi
        # Update Personal ZSH
    	if [ ! -z $ZSH_PERSONAL_DIR ]; then
		git -C $ZSH_PERSONAL_DIR pull
	fi

        # Reload scripts
        rld
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
