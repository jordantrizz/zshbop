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

#### -- kb
# A built in knowledge base.
kb () {
        if _cexists mdv; then mdv_reader=mdv; else mdv_reader=cat fi

        if [[ -a $ZSH_ROOT/help/$1.md ]]; then
                echo "Opening $ZSH_ROOT/help/$1.md"
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

# -- Linux Specific
findswap () { find /proc -maxdepth 2 -path "/proc/[0-9]*/status" -readable -exec awk -v FS=":" '{process[$1]=$2;sub(/^[ \t]+/,"",process[$1]);} END {if(process["VmSwap"] && process["VmSwap"] != "0 kB") printf "%10s %-30s %20s\n",process["Pid"],process["Name"],process["VmSwap"]}' '{}' \; | awk '{print $(NF-1),$0}' | sort -h | cut -d " " -f2- }

# -- ssh/sshkeys
pk () { ls -1 ~/.ssh/*.pub | xargs -L 1 -I {} sh -c 'cat {};echo '-----------------------------''}

# -- nginx
nginx-inc () { cat $1; grep '^.*[^#]include' $1 | awk {'print $2'} | sed 's/;\+$//' | xargs cat }

# -- exim
eximcq () { exim -bp | exiqgrep -i | xargs exim -Mrm }

# -- curl
vh () { vh_run=$(curl --header "Host: $1" $2 --insecure -i | head -50);echo $vh_run }

# -- openssl
check_ssl () { echo | openssl s_client -showcerts -servername $1 -connect $1:443 2>/dev/null | openssl x509 -inform pem -noout -text }

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
