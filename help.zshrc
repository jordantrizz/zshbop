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
		output_all=" -- Featching All Commands\n"
                for key in ${(k)help_files}; do
                        help_all_cat=(help_${key})
                        output_all+=" -- $key ------------------------------------------------------------\n"
                        for key value in ${(kv)${(P)help_all_cat}}; do
                    	    output_all+=$(printf '%s\n' "  ${(r:25:)key} - $value\n")
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
		for key value in ${(kv)${(P)help_cat}}; do
        		printf '%s\n' "  ${(r:25:)key} - $value"
        	done
        	echo ""
        fi
}

# -- Help
help () {
        HCMD=$@
        if [ ! $1 ]; then
		# print out help intro
        	help_intro
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
        for key value in ${(kv)help_zshbop}; do
                printf '%s\n' "  zshbop ${(r:25:)key} - $value"
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
        for key value in ${(kv)help_files}; do
                printf '%s\n' "  help ${(r:25:)key} - $value"
        done
	echo ""
	echo "---------------"
        echo "-- Examples --"
        echo "---------------"
        echo "$> help mysql"
        echo "$> help tools"
        echo ""

}
