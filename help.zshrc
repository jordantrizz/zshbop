# -- Help
help () {
	HCMD=$@
	if [ ! $1 ]; then
	        echo "** General help for $SCRIPT_NAME **"
	        echo "-----------------------------------"
	        echo " kb 		- Knowledge Base"
	        echo " help 		- this command"
	        echo " --"
	        echo " rld 		- reload this script"
	        echo " cc 		- clear antigen cache"
		echo " --"
	        echo " update 		- update this script"
	        echo " options 		- list all zsh functions"
		echo " --"
	        echo " checkenv 	- check environment tools"
	        echo " installenv 	- install environment tools via apt"
	        echo " customenv 	- install custom environment tools"
	        echo ""
	        echo "Examples:"
	        echo " --"
	        echo " help mysql"
	fi

	# -- MySQL
	if [ "$HCMD" = "mysql" ]; then
		echo "** Mysql Commands **"
		echo "--------------------"
#		typeset -A MYSQL_HELP
#		MYSQL_HELP[mysqldbsize]='Get size of all databases'
		for key value in ${(kv)MYSQL_HELP}; do
    			echo "$key 		-$value"
		done
	fi
        
}