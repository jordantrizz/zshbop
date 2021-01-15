# --------------
# -- Functions
# --------------
# This file contains all the required functions for the main .zshrc script.

# -----------------------
# -- One line functions
# -----------------------

# -- core functions
rld () { source $ZSH_ROOT/.zshrc }
_echo () { echo "$@" }
_debug () { if [[ $ZSH_DEBUG == 1 ]]; then echo "** DEBUG: $@"; fi }
clear_cache () { antigen reset } 
cmd () { } # describe all aliases (notworking)

# -- Linux Specific
findswap () { find /proc -maxdepth 2 -path "/proc/[0-9]*/status" -readable -exec awk -v FS=":" '{process[$1]=$2;sub(/^[ \t]+/,"",process[$1]);} END {if(process["VmSwap"] && process["VmSwap"] != "0 kB") printf "%10s %-30s %20s\n",process["Pid"],process["Name"],process["VmSwap"]}' '{}' \; | awk '{print $(NF-1),$0}' | sort -h | cut -d " " -f2- }

# -- ssh/sshkeys
pk () { ls -1 ~/.ssh/*.pub | xargs -L 1 -I {} sh -c 'cat {};echo '-----------------------------''}

# -- nginx
nginx-inc () { cat $1; grep '^.*[^#]include' $1 | awk {'print $2'} | sed 's/;\+$//' | xargs cat }

# -- exim
eximcq () { exim -bp | exiqgrep -i | xargs exim -Mrm }

# -- curl
function vh { vh_run=$(curl --header "Host: $1" $2 --insecure -i | head -50);echo $vh_run }

# -- mysql functions
mysqldbsize () { mysql -e 'SELECT table_schema AS "Database", ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)" FROM information_schema.TABLES GROUP BY table_schema;' }
mysqltablesize () { mysql -e "SELECT table_name AS \"Table\", ROUND(((data_length + index_length) / 1024 / 1024), 2) AS \"Size (MB)\" FROM information_schema.TABLES WHERE table_schema = \"${1}\" ORDER BY (data_length + index_length) DESC;" }
msds () { zgrep "INSERT INTO \`$2\`" $1 |  sed "s/),/),\n/g" } # needs to be documented.
mysqlmyisam () { mysql -e "select table_schema,table_name,engine,table_collation from information_schema.tables where engine='MyISAM';" }
mysqlmax () { mysql -e "
	SELECT ( @@key_buffer_size
	+ @@innodb_buffer_pool_size
	+ @@innodb_log_buffer_size
	+ @@max_allowed_packet
	+ @@max_connections * ( 
	    @@read_buffer_size
	    + @@read_rnd_buffer_size
	    + @@sort_buffer_size
	    + @@join_buffer_size
	    + @@binlog_cache_size
	    + @@net_buffer_length
	    + @@net_buffer_length
	    + @@thread_stack
	    + @@tmp_table_size )
	) / (1024 * 1024 * 1024) AS MAX_MEMORY_GB;"
}


# -- WSL Specific Aliases
alias wsl-screen="sudo /etc/init.d/screen-cleanup start"

# -- Software
vhwinfo () { wget --no-check-certificate https://github.com/rafa3d/vHWINFO/raw/master/vhwinfo.sh -O - -o /dev/null|bash }
yabs () { curl -sL yabs.sh | bash }
csf-install () { cd /usr/src; rm -fv csf.tgz; wget https://download.configserver.com/csf.tgz; tar -xzf csf.tgz; cd csf; sh install.sh }
github-cli () { sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0; sudo apt-add-repository https://cli.github.com/packages; sudo apt update; sudo apt install gh }


# ------------------
# -- Large Functions
# ------------------

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

# -- Init
init () {
        #- Include functions file
	_echo "-- Starting init"
	source $ZSH_ROOT/functions.zshrc
	source $ZSH_ROOT/aliases.zsh
	init_path
        init_omz_plugins
        init_antigen
        init_defaults
        init_sshkeys
	if [[ $ENABLE_ULTB == 1 ]]; then init_ultb; fi
	if [[ $ENABLE_UWT == 1 ]]; then init_uwt; fi
}

# -- PATHS!
init_path () {
        export PATH=$PATH:$HOME/bin:/usr/local/bin:$ZSH_ROOT
        export PATH=$PATH:$HOME/.local/bin
}

# -- Initialize oh-my-zsh plugins
init_omz_plugins () {
	_echo "-- Loading OMZ plugins"
	plugins=( git z )
	_echo " - $plugins"
}

# -- Initialize Antigen
init_antigen () {
	_echo "-- Loading Antigen"
        if [[ -a $ZSH_ROOT/antigen.zsh ]]; then
                _debug "- Loading antigen from $ZSH_ROOT/antigen.zsh";
		source $ZSH_ROOT/antigen.zsh
		antigen init $ZSH_ROOT/.antigenrc
        else
                _echo "	- Couldn't load antigen..";
        fi
}

# -- Load default zsh scripts
init_defaults () {
        _echo "-- Loading default scripts"
        source $ZSH_ROOT/defaults.zshrc

        # Find out if we have personal ZSH scripts.
        printf "-- Loading personal ZSH scripts...\n"
        if [[ -a $ZSH_ROOT/zsh-personal/.zshrc || -L $ZSH_ROOT/zsh-personal/.zshrc ]]; then
                ZSH_PERSONAL_DIR=$ZSH_ROOT/zsh-personal
        elif [[ -a $HOME/git/zsh-personal/.zshrc || -L $HOME/git/zsh-personal/.zshrc ]]; then
                ZSH_PERSONAL_DIR=$HOME/git/zsh-personal
        elif [[ -a $HOME/.personal.zshrc || -L $HOME/.personal.zshrc ]]; then
                ZSH_PERSONAL_SCRIPT=$HOME/.personal.zshrc
        fi

        # Source personal configuration
        if [ ! -z $ZSH_PERSONAL_DIR ]; then
                echo " - Loading $ZSH_PERSONAL_DIR/.zshrc"
                source $ZSH_PERSONAL_DIR/.zshrc
        elif [ ! -z $ZSH_PERSONAL_SCRIPT]; then
                echo " - Loading $ZSH_PERSONAL_SCRIPT"
                source $ZSH_PERSONAL_SCRIPT
        else
                printf " - No personal ZSH config loaded\n"
        fi
}

# -- Load default SSH keys into keychain
init_sshkeys () {
	_echo "-- Loading SSH keychain"
	if (( $+commands[keychain] )); then
	        # Load default SSH key
	        _debug " - Check for default SSH key $HOME/.ssh/id_rsa and load keychain"
        	if [[ -a $HOME/.ssh/id_rsa || -L $HOME/.ssh/id_rsa ]]; then
	                _debug  " - FOUND: $HOME/.ssh/id_rsa"
	                eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa`
	        else
	                _debug " - NOTFOUND: $HOME/.ssh/id_rsa"
        	fi

	        # Check and load custom SSH key
        	_debug " - Check for custom SSH key via $SSH_KEY and load keychain"
	        if [ ! -z "${SSH_KEY+1}" ]; then
        	        _debug " - FOUND: $SSH_KEY"
                	eval `keychain -q --eval --agents ssh $SSH_KEY`
	        else
        	        _debug " - NOTFOUND: $SSH_KEY not set."
	        fi

		# Load any id_rsa* keys
		if [[ $ENABLE_ALL_SSH_KEYS == 1 ]]; then
			eval `keychain -q --eval --agents ssh $HOME/.ssh/id_rsa*`
		fi
	else
		_echo " - Command keychain doesn't exist, please install for SSH keys to work"
	fi
}

# -- Ultimate Linux Tool Box
init_ultb () {
        if [[ -a $ZSH_ROOT/ultimate-linux-tool-box/.zshrc ]]; then
                _echo "-- Including Ultimate Linux Tool Box Paths"
                source $ZSH_ROOT/ultimate-linux-tool-box/.zshrc
	fi
       	export PATH=$PATH:$ZSH_ROOT/ultimate-linux-tool-box
}

# -- Ultimate WordPress Tools
init_uwt () {
        if [[ -a $ZSH_ROOT/ultimate-wordpress-tools/.zshrc ]]; then
                _echo "-- Including Ultimate WordPress Tools"
                source $ZSH_ROOT/ultimate-wordpress-tools/.zshrc
	fi
	export PATH=$PATH:$ZSH_ROOT/ultimate-wordpress-tools
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

####-- Setup Environment
setup_environment () {
	sudo apt install $default_tools
	echo "gh - installed separately, run github-cli"
	echo "install_environment - install more tools"
	#keychain mosh traceroute mtr keychain pwgen tree ncdu fpart whois pwgen
	#sudo apt install python-pip npm # Skipping python dependencies
	#sudo pip install apt-select # Skipping python dependencies
       	#sudo npm install -g gnomon # Skipping node dependencies
}

####-- Install Environment
# Custom install of some much needed tools!
install_environment () {
	# Need to add in check for pip3
	pip3 install -U checkdmarc
}

####-- Update
update () {
        git -C $ZSH_ROOT pull
	# Updated sub-modules
	if [[ $1 == "-f" ]]; then
	        git -C $ZSH_ROOT pull --recurse-submodules
	        git -C $ZSH_ROOT submodule update --init --recursive
        	git -C $ZSH_ROOT submodule update --recursive --remote
	fi
        # Update Personal ZSH
    	if [ ! -z $ZSH_PERSONAL_DIR ]; then
		git -C $ZSH_PERSONAL_DIR pull
	fi

        # Reload scripts
        rld
}

####-- List current functions available to zsh
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


#### -- Help
help () { 
	if _cexists mdv; then mdv_reader=mdv; else mdv_reader=cat fi
        if [ ! -z $1 ]; then
		$mdv_reader $ZSH_ROOT/help/$1.md
        else
        	ls -l $ZSH_ROOT/help
        fi
        if [[ $mdv_reader == cat ]]; then
                echo "\n\n"
                echo "---------------------------------------"
                echo "mdv not avaialble failing back to cat"
                echo "you should install mdv, pip install mdv"
        fi
}