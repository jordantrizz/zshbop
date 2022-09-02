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

_debug "Loading mypath=${0:a}"

# -- Arrays
typeset -gA help_files
typeset -gA help_files_description
help_categories=()

# -- Help header
help_sub_header () {
		echo "----------------------"
                echo "-- $HCMD"
                echo "----------------------"
}

get_category_commands () {	
	_debug_function
	
	# If help all is used
	_debug "-- Finding category: $HCMD"
        if [[ $HCMD == "all" ]]; then
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
	elif [[ -z ${(P)HELP_CAT} ]]; then
        	echo "No command category $HCMD, try running kb $HCMD"
                echo ""
		return
	else
		echo "-- $HCMD ---"
		echo $help_files_description[${HCMD}]
		echo "----------------------------------------------------------------------"
		for key in ${(kon)${(P)HELP_CAT}}; do
        		printf '%s\n' "  ${(r:25:)key} - ${${(P)HELP_CAT}[$key]}"
        	done
        	echo ""
        fi
}

# -- Help
help () {
		# Full help command into $HCMD
        HCMD=$@
        _debug "\$HCMD: $HCMD"
        
        # Aliases
        if [[ $HCMD == "wp" ]]; then; HCMD="wordpress";fi
        if [[ $HCMD == "cf" ]]; then; HCMD="cloudflare";fi
        _debug "After aliases \$HCMD: $HCMD"

		# Print out help intro if no arguments passed, otherwise run get_category_commands
        if [ ! $HCMD ]; then
        	help_intro | less
        else
        	HELP_CAT=(help_${HCMD})
			get_category_commands $HCMD
        fi
}

# -- Help introduction
help_intro () {
	echo "-----------------------------"
	echo "-- Welcome to $SCRIPT_NAME --"
    echo "-----------------------------"
    echo ""
    echo "ZSHBop contains a number of built-in functions, scripts and binaries."
    echo "This help command will list all that are available."
	echo ""
	echo "You can request help on any of the following categories by typing help <category>"
	echo ""

	# -- Go through help_zshbop
    echo "------------"
    echo "-- zshbop --"
    echo "------------"
    echo ""        
    for key in ${(kon)help_zshbop}; do
    	printf '%s\n' "  zshbop ${(r:25:)key} - ${help_zshbop[$key]}"
    done

	# -- Go through help_core variables
	echo ""
	echo "----------"
    echo "-- core --"
    echo "----------"
    echo ""
	
    for key in ${(kon)help_core}; do
        printf '%s\n' "  ${(r:25:)key} - ${help_core[$key]}"
    done

	# -- Go through help_files variable
	echo ""
	echo "------------------"
	echo "-- all commands --"
    echo "------------------"
	echo ""	
    for key in ${(kon)help_files}; do
		printf '%s\n' "  ${(r:25:)key} - $help_files[$key]"
    done
	
	# -- Custom help files.
	echo ""
	echo "Checking for \$help_custom"
	_debug "$help_custom"
    if [[ -n $help_custom ]]; then
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

	# -- Examples
	
	echo ""
	echo "---------------"
        echo "-- Examples --"
        echo "---------------"
        echo "$> help mysql"
        echo "$> help tools"
        echo ""

}
