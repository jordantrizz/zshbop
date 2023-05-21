#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- help.zsh - Help function and it's associated functions
# -----------------------------------------------------------------------------------
# -- The following script handles all of the help information for fucntions and scripts added throughout.a
# -- To add command help, which is a file within this repostiryo and not a function.
# -- help_mysql[maxmysqlmem]='Calculate maximum MySQL memory'
# -----------------------------------------------------------------------------------
_debug_load

# -- auto completion - needs to be at the end of this file.
function _help  {    
    compadd $(help auto)
}
compdef _help help

# -- Help header
help_sub_header () {	
    loading "$HCMD"
}

# -- get_category_commands ($category)
get_category_commands () {	
	_debug_all
	
	# If help all is used
	_debug "Finding category: $HCMD"
    if [[ $HCMD == "all" ]]; then
		output_all=$(_loading "All Commands\n")
        for key in ${(kon)help_files}; do
            help_all_cat=(help_${key})
            output_all+=$(_loading2 "-- $key --------\n")
            for key in ${(kon)${(P)help_all_cat}}; do
                output_all+=$(printf '%s\n' "  ${(r:25:)key} - ${${(P)help_all_cat}[$key]}\n")
            done
            output_all+="\n"
		done
		echo $output_all | less        
    elif [[ $HCMD == "auto" ]]; then		

        for key in ${(kon)help_files}; do                        
            echo "$key"
		done
	elif [[ -z ${(P)HELP_CAT} ]]; then
        _debug "\${(P)HELP_CAT}: ${(P)HELP_CAT}"
        _error "No command category $HCMD, try running kb $HCMD"
        echo ""		
	else
		_loading "-- $HCMD -------- $help_files[${HCMD}] --------"	
        echo ""
		for key in ${(kon)${(P)HELP_CAT}}; do
            printf '%s\n' "  ${(r:25:)key} - ${${(P)HELP_CAT}[$key]}"
        done
        echo ""
    fi
}
    
# -- get_category_commands_custom ($category)
function get_category_commands_custom () {
    if [[ $cmdsc_files[$HCMD] ]]; then
        CMDSC_CMDS=(cmdsc_$HCMD)
        echo ""
        _loading2 "-- $HCMD - Custom - $cmdsc_files[$HCMD] --------"
        echo ""
        for key in ${(kon)${(P)CMDSC_CMDS}}; do
            printf '%s\n' "  ${(r:25:)key} - ${${(P)CMDSC_CMDS}[$key]}"
        done
        echo ""
    elif [[ $HCMD == "auto" ]]; then
        CMDSC_CMDS=(cmdsc_$HCMD)
        for key in ${(kon)${(P)CMDSC_CMDS}}; do
            echo $key
        done
    else    
        _error "No custom command category $HCMD, try running kb $HCMD"
        echo ""
		return
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
        if [[ ! $HCMD ]]; then
        	help_intro | less
        elif [[ $HCMD == "auto" ]]; then
        	get_category_commands auto
            get_category_commands_custom auto
        else
        	HELP_CAT=(help_${HCMD})
			get_category_commands $HCMD
            get_category_commands_custom $HCMD
        fi
}

# -- Help introduction
help_intro () {
	_loading " Welcome to $ZSHBOP_NAME"
    echo ""
    echo "ZSHBop contains a number of built-in functions, scripts and binaries. This help command will list all that are available."
	echo "You can request help on any of the following categories by typing help <category>"
	echo ""

	# -- Go through help_zshbop
    _loading2 "    zshbop    "
    echo ""        
    for key in ${(kon)help_zshbop}; do
    	printf '%s\n' "  zshbop ${(r:25:)key} - ${help_zshbop[$key]}"
    done

	# -- Go through help_core variables
    echo ""
    _loading2 "    Core    "
    echo ""
	
    for key in ${(kon)help_core}; do
        printf '%s\n' "  ${(r:25:)key} - ${help_core[$key]}"
    done

	# -- Go through help_files variable
    echo ""
    _loading2 "    All Categories    "
    echo ""
    for key in ${(kon)help_files}; do
		printf '%s\n' "  ${(r:25:)key} - $help_files[$key]"
    done
	
	# -- Custom help files.
	echo ""
	_loading "Checking for \$cmdsc_files"
	_debug "$cmdsc_files"
    if [[ -n $cmdsc_files ]]; then
		_debug "Loading custom commands"
        echo ""
        _loading2 "    Custom Command Categories    "
        echo ""
		for key value in ${(kv)cmdsc_files}; do
	    	printf '%s\n' "  chelp ${(r:25:)key} - $value"
	    done
	else
		_debug "No custom commands found in $HOME/.zshbop"
	fi

	# -- Examples
	
	echo ""
    _loading2 "    Examples    "
    echo "$> help mysql"
    echo "$> help tools"
    echo ""
}
