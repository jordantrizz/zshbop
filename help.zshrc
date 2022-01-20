# ----------------------------------------------
# -- Help function and it's associated functions
# ----------------------------------------------

# -- Help
help () {
        HCMD=$@
        if [ ! $1 ]; then
        	help_intro
        else
        	echo "-- $HCMD"
		echo "**********************"
                if [ "$HCMD" = "all" ]; then 
                	echo "-- core --"
                	help_core_cmd
                	echo "-- mysql --"
                	help_mysql_cmd
                	echo "-- ssh --"
                	help_ssh_cmd
                fi
                if [ "$HCMD" = "core" ]; then help_core_cmd; fi
                if [ "$HCMD" = "mysql" ]; then help_mysql_cmd; fi
                if [ "$HCMD" = "ssh" ]; then help_ssh_cmd; fi
                
        fi
}

# -- Help introduction
help_intro () {
        echo "** General help for $SCRIPT_NAME **"
        echo "-----------------------------------"
        echo " kb 		- Knowledge Base"
        echo " help 		- this command"
        echo " --"
	echo " help all		- List all commands"
	echo " help core	- List core commands"
	echo " help mysql	- List mysql commands"
	ehco " help ssh		- List ssh commands"
	echo ""
        echo "Examples:"
        echo " --"
        echo " help mysql"

}
# -- Core commands
help_core_cmd () {
        for key value in ${(kv)help_core}; do
                echo "    $key			- $value"
        done        
}

# -- MySQL commands
help_mysql_cmd () {
	echo " -- Commands"
        for key value in ${(kv)help_mysql}; do
                echo "    $key			- $value"
        done
        echo ""
        echo " -- Scripts"
        for key value in ${(kv)help_mysql_scripts}; do
                echo "    $key                  - $value"
        done
}

# -- Mysql
help_ssh_cmd () {
        for key value in ${(kv)help_ssh}; do
                echo "    $key			- $value"
        done
}