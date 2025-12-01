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
    local ACTION=$1
	_debug_all
    # If help all is used
	_debug "Finding category: $ACTION"
    if [[ $ACTION == "all" ]]; then
		output_all=$(_loading "All Commands\n")
        for key in ${(kon)help_files}; do
            help_all_cat=(help_${key})
            output_all+=$(_loading2 "-- $key --------\n")
            for key in ${(kon)${(P)help_all_cat}}; do
                # Skip internal commands (those starting with _)
                if [[ $key == _* ]]; then
                    continue
                fi
                output_all+=$(printf '%s\n' "  ${(r:25:)key} - ${${(P)help_all_cat}[$key]}\n")
            done
            output_all+="\n"
		done
		# Preserve formatting when paging
		printf "%s" "$output_all" | less
    elif [[ $ACTION == "auto" ]]; then
        echo ${ALL_HELP_CATEGORIES[@]}
    elif [[ $ACTION == "auto-cmd" ]]; then
        echo ${ALL_HELP_COMMANDS[@]}
	elif [[ -z ${(P)HELP_CAT} ]]; then
        _debug "\${(P)HELP_CAT}: ${(P)HELP_CAT}"
        _loading "-- $ACTION - Core --------"
        _error "No command or category $ACTION, try running kb $ACTION"
        echo
        _loading2 "Potential Matches"    
        for key in ${(kon)ALL_HELP_COMMANDS}; do
            if [[ $key == *"$ACTION"* ]]; then
                echo "$key"
            fi
        done
        echo
	else
		_loading "-- $ACTION -------- $help_files[${ACTION}] --------"
        echo
		for key in ${(kon)${(P)HELP_CAT}}; do
            # Skip internal commands (those starting with _)
            if [[ $key == _* ]]; then
                continue
            fi
            printf '%s\n' "  ${(r:25:)key} - ${${(P)HELP_CAT}[$key]}"
        done
        echo
    fi
}

# -- get_category_commands_custom ($category)
function get_category_commands_custom () {
    local ACTION=$1
    if [[ $cmdsc_files[$ACTION] ]]; then
        CMDSC_CMDS=(cmdsc_$ACTION)
        echo
        _loading2 "-- $ACTION - Custom - $cmdsc_files[$ACTION] --------"
        echo
        for key in ${(kon)${(P)CMDSC_CMDS}}; do
            printf '%s\n' "  ${(r:25:)key} - ${${(P)CMDSC_CMDS}[$key]}"
        done
        echo
    elif [[ $ACTION == "auto" ]]; then
        echo ${ALL_HELP_CATEGORIES_CUSTOM[@]}
    elif [[ $ACTION == "auto-cmd" ]]; then
        echo ${ALL_HELP_COMMANDS_CUSTOM[@]}
    else
        _loading "-- $ACTION - Custom --------"
        _error "No custom command or category $ACTION, try running kb $ACTION"
        echo
        _loading2 "Potential Matches"    
        for key in ${(kon)ALL_HELP_COMMANDS_CUSTOM}; do
            if [[ $key == *"$ACTION"* ]]; then
                echo "$key"
            fi
        done
		return
        echo
    fi
}

# -- Help
help_core[help]="Display all available commands"
help () {
		# All arguments $@ into $HCMD
        HCMD=$@
        _debug "\$HCMD: $HCMD"

        # Common Aliases
        if [[ $HCMD == "wp" ]]; then; HCMD="wordpress";fi
        if [[ $HCMD == "cf" ]]; then; HCMD="cloudflare";fi
        _debug "After aliases \$HCMD: $HCMD"

		# Print out help intro if no arguments passed, otherwise run get_category_commands
        if [[ ! $HCMD ]]; then
        	help_intro | less
        elif [[ $HCMD == "auto" ]]; then
        	get_category_commands auto
            get_category_commands_custom auto
        elif [[ $HCMD == "auto" ]]; then
        	get_category_commands auto-cmd
            get_category_commands_custom auto-cmd
        else
			# If it's a valid category (help_<category> exists), show that category
			local cat_var=(help_${HCMD})
			if typeset -p $cat_var &>/dev/null; then
				HELP_CAT=($cat_var)
				get_category_commands $HCMD
                get_category_commands_custom $HCMD
			else
				# Not a category; try to show matching commands (exact and fuzzy)
				if ! help_search "$HCMD"; then
					_error "No command or category $HCMD found"
					# Fallback to old potential matches list
					_loading2 "Potential Matches"
					for key in ${(kon)ALL_HELP_COMMANDS}; do
						if [[ $key == *"$HCMD"* ]]; then
							echo "$key"
						fi
					done
				fi
			fi
        fi
}

# Search and display matching categories and commands
# Usage: help_search <term>
help_search () {
    local term
    term="$1"
    if [[ -z "$term" ]]; then
        return 1
    fi

    local lc_term
    lc_term="${term:l}"
    local -a category_matches
    category_matches=()
    local -a command_matches
    command_matches=()
    local desc cat_lc desc_lc assoc cmd_desc cmd_lc cmd_desc_lc cat cmd

    # Categories and their descriptions
    for cat in ${(kon)help_files}; do
        desc="$help_files[$cat]"
        cat_lc="${cat:l}"
        desc_lc="${desc:l}"
        if [[ $cat_lc == *$lc_term* || $desc_lc == *$lc_term* ]]; then
            category_matches+=("$cat"$'\t'"$desc")
        fi

        assoc="help_${cat}"
        if typeset -p $assoc &>/dev/null; then
            for cmd in ${(kon)${(P)assoc}}; do
                # Skip internal commands
                if [[ $cmd == _* ]]; then
                    continue
                fi
                cmd_desc="${${(P)assoc}[$cmd]}"
                cmd_lc="${cmd:l}"
                cmd_desc_lc="${cmd_desc:l}"
                if [[ $cmd_lc == *$lc_term* || $cmd_desc_lc == *$lc_term* ]]; then
                    command_matches+=("$cat"$'\t'"$cmd"$'\t'"$cmd_desc")
                fi
            done
        fi
    done

    # If nothing matched, bail
    if (( ${#category_matches} == 0 && ${#command_matches} == 0 )); then
        return 1
    fi

    if (( ${#category_matches} )); then
        _loading "Matching categories for '$term':"
        for entry in "${category_matches[@]}"; do
            IFS=$'\t' read -r cat desc <<< "$entry"
            printf '  %-20s - %s\n' "$cat" "$desc"
        done
        echo
    fi

    if (( ${#command_matches} )); then
        _loading "Matching commands for '$term':"
        local prev_cat
        prev_cat=""
        for entry in "${command_matches[@]}"; do
            IFS=$'\t' read -r cat cmd desc <<< "$entry"
            if [[ "$cat" != "$prev_cat" ]]; then
                if [[ -n "$prev_cat" ]]; then
                    echo ""
                fi
                _loading2 "Category: $cat"
                prev_cat="$cat"
            fi
            printf '  %-25s - %s\n' "$cmd" "$desc"
        done
        echo
    fi

    return 0
}

# -- Help introduction
help_intro () {
	_loading " Welcome to $ZSHBOP_NAME"
    echo
    echo "ZSHBop contains a number of built-in functions, scripts and binaries. This help command will list all that are available."
	echo "You can request help on any of the following categories by typing help <category>"
	echo

	# -- Go through help_zshbop
    _loading2 "    zshbop    "
    echo
    for key in ${(kon)help_zshbop}; do
    	printf '%s\n' "  zshbop ${(r:25:)key} - ${help_zshbop[$key]}"
    done

	# -- Go through help_core variables
    echo
    _loading2 "    Core    "
    echo

    for key in ${(kon)help_core}; do
        printf '%s\n' "  ${(r:25:)key} - ${help_core[$key]}"
    done

	# -- Go through help_files variable
    echo
    _loading2 "    All Categories    "
    echo
    for key in ${(kon)help_files}; do
		printf '%s\n' "  ${(r:25:)key} - $help_files[$key]"
    done

	# -- Custom help files.
	echo
	_loading "Checking for \$cmdsc_files"
	_debug "$cmdsc_files"
    if [[ -n $cmdsc_files ]]; then
		_debug "Loading custom commands"
        echo
        _loading2 "    Custom Command Categories    "
        echo
		for key value in ${(kv)cmdsc_files}; do
	    	printf '%s\n' "  chelp ${(r:25:)key} - $value"
	    done
	else
		_debug "No custom commands found in $HOME/.zshbop"
	fi

	# -- Examples

	echo
    _loading2 "    Examples    "
    echo "$> help mysql"
    echo "$> help tools"
    echo
}

init_help () {
    _debug "Loading help commands into array"
    ALL_HELP_CATEGORIES=()
    ALL_HELP_COMMANDS=()
    ALL_HELP_CATEGORIES_CUSTOM=()
    ALL_HELP_COMMANDS_CUSTOM=()

    # -- Load help file categories into array
    for key in ${(kon)help_files}; do
        ALL_HELP_CATEGORIES+=($key)
	done

    # -- Load help file categories into array
    for key in ${(kon)help_files}; do
        help_all_cat=(help_${key})
        for key in ${(kon)${(P)help_all_cat}}; do
            ALL_HELP_COMMANDS+=($key)
        done
    done

    # -- Custom help categories
    if [[ -n $cmdsc_files ]]; then
        for key value in ${(kv)cmdsc_files}; do
            ALL_HELP_CATEGORIES_CUSTOM+=($key)
        done
    fi

    # -- Custom help commands
    for key value in ${(kv)cmdsc_files}; do
        CMDSC_CMDS=(cmdsc_$key)
        for key in ${(kon)${(P)CMDSC_CMDS}}; do
            ALL_HELP_COMMANDS_CUSTOM+=($key)
        done
    done

    export ALL_HELP_CATEGORIES
    export ALL_HELP_COMMANDS

    # -- Print out commands and categories count
    _log "Loaded help - Categories ${#ALL_HELP_CATEGORIES} - Commands ${#ALL_HELP_COMMANDS} - Custom Categories ${#ALL_HELP_CATEGORIES_CUSTOM} - Custom Commands ${#ALL_HELP_COMMANDS_CUSTOM}"
}