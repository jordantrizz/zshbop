# ----------------------------------------------
# -- help function and it's associated functions
# ----------------------------------------------
#
# The following script handles all of the help information for fucntions and scripts added throughout.
#
# - To add command help, which is a file within this repostiryo and not a function.
#
# 	help_mysql[maxmysqlmem]='Calculate maximum MySQL memory'
#

echo "-- Loading help.zshrc"

# Set Arrays
typeset -gA help_files
help_topics=()

# -- Help header
help_sub_header () {
		echo "----------------------"
                echo "-- $HCMD"
                echo "----------------------"
}

get_category_commands () {	
	# If help all is used
	_debug "-- Finding category: $1"
        if [[ $1 == "all" ]]; then
		output_all=" -- All Commands\n"
                for key in ${(kon)help_files}; do
                        help_all_cat=(help_${key})
                        output_all+=" -- $key ------------------------------------------------------------\n"
                        for key in ${(kon)${(P)help_all_cat}}; do
                    	    output_all+=$(printf '%s\n' "  ${(r:25:)key} - ${${(P)help_all_cat}[$key]}\n")
                    	done
                    	output_all+="\n"
		done
		echo $output_all | less
	elif [[ -z ${(P)help_cat} ]];then
        	echo "No command category $HCMD, try running kb $HCMD"
                echo ""
		return
	else
		echo ""
		echo $help_files[$1_description]
		echo " -- $1 ------------------------------------------------------------"
		for key in ${(kon)${(P)help_cat}}; do
        		printf '%s\n' "  ${(r:25:)key} - ${${(P)help_cat}[$key]}"
        	done
        	echo ""
        fi
}

# -- Help
help () {
        HCMD=$@
        if [ ! $1 ]; then
		# print out help intro
        	help_intro | less
        else
        	help_cat=(help_${1})
		get_category_commands $1
        fi
}

# -- Help introduction
help_intro () {
	echo "-----------------------------"
	echo "-- General help for $SCRIPT_NAME --"
        echo "-----------------------------"
        echo ""
        echo "ZSHBop contains a number of built-in functions, scripts and binaries."
        echo "This help command will list all that are available."
        echo ""
        echo "--------------------"
        echo "-- zshbop Commands --"
        echo "--------------------"
        echo ""
        
	
        for key in ${(kon)help_zshbop}; do
                printf '%s\n' "  zshbop ${(r:25:)key} - help_zshbop[$key]"
        done

	echo ""
        echo "--------------------"
        echo "-- Help Commands --"
        echo "--------------------"
        echo ""
        echo " kb 		- Knowledge Base"
        echo " help 		- this command"
	echo ""
	echo "------------------------"
	echo "-- Help Command Categories --"
        echo "------------------------"
	echo ""
	
		
        for key in ${(kon)help_files}; do
                printf '%s\n' "  help ${(r:25:)key} - $help_files[$key]"
        done
	_debug "Checking for \$help_custom"
	_debug "$help_custom"
        if [[ $help_custom ]]; then
		_debug "Loading custom commands"
	        echo "-----------------------"
	        echo "-- Custom Commands --"
	        echo "-----------------------"
		for key value in ${(kv)help_custom}; do
	                printf '%s\n' "  help ${(r:25:)key} - $value"
	        done
	else
		_debug "No custom commands found in $HOME/.zshbop"
	fi
	
	echo ""
	echo "---------------"
        echo "-- Examples --"
        echo "---------------"
        echo "$> help mysql"
        echo "$> help tools"
        echo ""

}
