#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- kb.zsh -- Knowledge Base (KB) functions
# -----------------------------------------------------------------------------------
_debug_load

# -- kbc
alias kbc="kb -c"
alias kbd="cd ${KB}"

# -- Init kb-aliases.zsh
function kb_init_aliases () {

    if [[ -f $ZSHBOP_ROOT/kb/kb-aliases.zsh ]]; then
        source $ZSHBOP_ROOT/kb/kb-aliases.zsh
    fi
}

# ==================================================
# -- Init kb-topics.zsh
# -- This function will create a multi dimensional array to store all the KB topics
# ==================================================
function kb_init_topics () {    
    # -- Check if kb directory exists
    if [[ -d $ZSHBOP_ROOT/kb ]]; then        
        KB_DIR="$ZSHBOP_ROOT/kb"                
        _debug "Found and processing KB directory $KB_DIR"      
        local KB_FILE KB_TOPIC KB_TOPIC_FILE KB_TOPIC_DESC KB_DIRS KB_TAG
        # -- Create multi dimensional array
        typeset -gA kb_topics
        typeset -gA kb_topics_desc
        #typeset -gA kb_topics_tag  

        # -- Go through all files and create an array
        for KB_FILE in $KB_DIR/*.md; do
            # -- Get the file name and add to array
            KB_TOPIC=$(basename $KB_FILE| sed s/.md//g)
            kb_topics[$KB_TOPIC]=$KB_FILE
            # -- Get Topic Description and add to array
            KB_TOPIC_DESC=$(grep -E '^#\$\$#' $KB_FILE | sed 's/#$$# //g')            
            kb_topics_desc[$KB_TOPIC]=$KB_TOPIC_DESC
            # -- KB tag # TODO need to figure out tagging kbs                    
            #kb_topics_tag[$KB_TOPIC]=$KB_DIR_ID
        done    
    fi

    # -- Check if kb directory exists
    if [[ -d $ZBC/kb ]]; then
        local KB_DIR_CUSTOM KB_FILE_CUSTOM KB_TOPIC_CUSTOM KB_TOPIC_DESC_CUSTOM KB_TOPIC_TAG_CUSTOM
        # -- Create multi dimensional array for custom kb's
        typeset -gA kb_topics_custom
        typeset -gA kb_topics_desc_custom
        #typeset -gA kb_topics_tag_custom     
        
        KB_DIR_CUSTOM="$ZBC/kb"
        _debug "Found and processing Custom KB directory $ZBC/kb"        
            
        # -- Go through all files and create an array
        for KB_FILE_CUSTOM in $KB_DIR_CUSTOM/*.md; do
            # -- Get the file name and add to array
            KB_TOPIC_CUSTOM=$(basename $KB_FILE_CUSTOM| sed s/.md//g)
            kb_topics_custom[$KB_TOPIC_CUSTOM]=$KB_FILE_CUSTOM
            # -- Get Topic Description and add to array
            KB_TOPIC_DESC_CUSTOM=$(grep -E '^#\$\$#' $KB_FILE_CUSTOM | sed 's/#$$# //g')            
            kb_topics_desc_custom[$KB_TOPIC_CUSTOM]=$KB_TOPIC_DESC_CUSTOM
            # -- KB tags # TODO need to figure out tagging kbs            
            #kb_topics_tag_custom[$KB_TOPIC_CUSTOM]=
        done   
    fi     
}

# ==================================================
# -- kb_print_topics
# -- This function will print out all the KB topics in a nice format
# ==================================================
function kb_print_topics () {
    local KB_TOPIC KB_OUTPUT OUTPUT_STYLE KB_TOPIC_DESC
    OUTPUT_STYLE=${1:-c}
    # -- Print out all the KB topics and sort

    # -- Print out all the KB topics into a table and sort
    # $1 = kb_topics or kb_topics_custom
    function _kb_print_topics_table () {
        local KB_OUTPUT KB_OUTPUT2 KB_TOPIC KB_TOPIC_DESC KB_TOPIC_FILE
        local RKB_TOPIC_TYPE="${1}"
        local RKB_TOPIC_DESC="${1}_desc"
        local RKB_TOPIC_FILE="${1}"

        KB_OUTPUT="Topic\tDescription\tFile\n"
        KB_OUTPUT+="-----\t-----------\t----\n"
        for KB_TOPIC in ${(konP)RKB_TOPIC_TYPE}; do            
            [[ -z ${${(P)RKB_TOPIC_DESC}[$KB_TOPIC]} ]] && KB_TOPIC_DESC="--" || KB_TOPIC_DESC="${${(P)RKB_TOPIC_DESC}[$KB_TOPIC]}"            
            KB_TOPIC_FILE="${${(P)RKB_TOPIC_TYPE}[$KB_TOPIC]}"
            KB_OUTPUT+="$KB_TOPIC\t${KB_TOPIC_DESC}\t${KB_TOPIC_FILE}\n"
        done        
        KB_OUTPUT2+=$(echo $KB_OUTPUT | column -t -s $'\t')
        echo "$KB_OUTPUT2"
    }
    
    if [[ $OUTPUT_STYLE == "c" ]]; then
        {_banner_yellow "KB Topics"
        _kb_print_topics_table kb_topics
        echo ""
        _banner_yellow "Custom KB Topics"
        _kb_print_topics_table kb_topics_custom } | less
    elif [[ $OUTPUT_STYLE == "_auto" ]]; then
        _debug "Running autocomplete"
        AUTO_KB=()
        for KB_TOPIC in ${(kon)kb_topics}; do
            AUTO_KB+=($KB_TOPIC)
        done
        # -- Add custom KB topics but don't add duplicate
        for KB_TOPIC_CUSTOM in ${(kon)kb_topics_custom}; do
            if [[ ! ${AUTO_KB[(r)$KB_TOPIC_CUSTOM]} ]]; then
                AUTO_KB+=($KB_TOPIC_CUSTOM)
            fi
        done
        echo $AUTO_KB
    fi    
}

# ==================================================
# -- kb_search
# -- This function will search for a KB article
# ==================================================
function kb_search () {
    local KB_SEARCH OUTPUT
    KB_SEARCH="$1"
    _loading3 "Searching for KB article $KB_SEARCH in KB topics"        
    for KB_TOPIC in ${(kon)kb_topics}; do
        if [[ $KB_TOPIC == *$KB_SEARCH* ]]; then
            echo "$KB_TOPIC\n"
        fi
    done
    _loading3 "Searching in Custom KB topics"
    for KB_TOPIC_CUSTOM in ${(kon)kb_topics_custom}; do
        if [[ $KB_TOPIC_CUSTOM == *$KB_SEARCH* ]]; then
            echo "$KB_TOPIC_CUSTOM\n"            
        fi
    done
}

# ==================================================
# -- kb_usage
# -- This function will print out the usage of the kb command
# ==================================================
function kb_usage () {
    _banner_yellow "Current KB Articles"
    \ls $ZSH_ROOT/kb

    if [[ -d $ZBC/kb ]]; then				
        _banner_yellow "Current Custom KB Articles"
        \ls $ZBC/kb
    fi   
}

# ==================================================
# -- kb_set_md_reader
# -- This function will set the MD_READER variable to the best available md reader
# ==================================================
kb_set_md_reader () {
    if [[ $MD_READER ]]; then
        _debug "MD_READER already set to $MD_READER"
    fi
    _debug "Checking if other md readers are available"

    if [[  $(command -v glow) ]]; then
        MD_READER="glow"
        _debug "Setting MD_READER to glow"
    elif [[ $(command -v mdv) ]]; then
        MD_READER="mdv"
        _debug "Setting MD_READER to mdv"
    else
        MD_READER="cat"
        _debug "Setting MD_READER to cat as no other md readers found"
    fi
}

# ==================================================
# -- md-reader
# -- This function will read a markdown file and display it in the best available md reader
# ==================================================
function md-reader () {
    MD_FILE="$1"
    if [[ $MD_READER == "cat" ]]; then
        echo "exec: cat $MD_FILE"
		cat $MD_FILE
	elif [[ $MD_READER == "glow" ]]; then
        echo "exec: $MD_READER -p $MD_FILE"
		eval $MD_READER -p $MD_FILE
	elif [[ $MD_READER == "mdv" ]]; then
		echo "exec: $MD_READER $MD_FILE | less"
        eval $MD_READER $MD_FILE | less
	else
        echo "exec: less $MD_FILE"
		less $MD_FILE
	fi    
}

# ====================================================================================================
# -- kb - A built in knowledge base.
# --
# -- Usage:
# -- kb <article>
# ====================================================================================================
function kb () {    
    # -- args
    zparseopts -D -E c=CAT
    if [[ -n "$CAT" ]]; then
        echo "Using cat on $1"
        MD_READER="cat"
    fi
    KB="$1"

    # -- debug function
    _debug_all

    # -- set md reader
    kb_set_md_reader

    # -- Auto complete KB articles.
    if [[ $KB == "_auto" ]]; then
        _debug "Running autocomplete"
        kb_print_topics _auto
    # -- List KB articles.
    elif [[ $KB == "list" ]]; then
        kb_usage
        return 0
    # -- Check if kb file exists
    elif [[ -z $KB ]]; then
        kb_usage
        return 1
    elif [[ -n $KB ]]; then
        # -- Check if topic exists
        if [[ -z $kb_topics[$KB] ]]; then
            _banner_red "KB topic $KB not found"
            kb_search $KB            
            return 1
        else
            _banner_yellow "Found KB file $kb_topics[$KB], showing via $MD_READER"
            _debug "Running $MD_READER $kb_topics[$KB]"
            md-reader $kb_topics[$KB]
        fi
    # TODO Incorporate custom KB articles.
    elif [[ -a $ZSHBOP_ROOT/kb/${KB}.md ]] && [[ -a $ZBC/kb/${KB}.md ]]; then
        _banner_yellow "Found both zshbop and zshbop custom KB file, showing both via $MD_READER"
        KB_COMBINED="\n"
        KB_COMBINED+="---- $ZSHBOP_ROOT/kb/${KB}.md ----\n"
        KB_COMBINED+="\n"
        KB_COMBINED+=$(cat $ZSHBOP_ROOT/kb/${KB}.md)
        KB_COMBINED+="\n"
        KB_COMBINED+="---- $ZBC/kb/${KB}.md ----\n"
        KB_COMBINED+="\n"
        KB_COMBINED+=$(cat $ZBC/kb/${KB}.md)
        _debug "$KB_COMBINED"
        md-reader-text $KB_COMBINED
    else
        kb_usage
        return 1
    fi
}



md-reader-text () {
    MD_TEXT="$1"
    if [[ $MD_READER == "cat" ]]; then
		echo $MD_TEXT
	elif [[ $MD_READER == "glow" ]]; then
		echo $MD_TEXT | eval $MD_READER -
	elif [[ $MD_READER == "mdv" ]]; then
		echo $MD_TEXT | eval $MD_READER | less
	else
		echo $MD_TEST | less
	fi

    # -- alert to install mdv for better experience
    if [[ $MD_READER == cat ]]; then
        _notice "mdv not avaialble failing back to cat, trying installing mdv by typing"
    fi
}


# -- auto completion - needs to be at the end of this file.
function _kb  {    
    compadd $(kb _auto)
}
compdef _kb kb