#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- kb.zsh -- Knowledge Base (KB) functions
# -----------------------------------------------------------------------------------
_debug_load

# -- KB lazy loading flag
typeset -g ZSHBOP_KB_LOADED=0

# -- Ensure KB topics are loaded (for lazy loading)
function _kb_ensure_loaded () {
    if [[ $ZSHBOP_KB_LOADED -eq 1 ]]; then
        return 0
    fi
    _debug "Lazy loading KB topics..."
    kb_init_topics
    ZSHBOP_KB_LOADED=1
}

# -- kbc
alias kbc="kb -c"
alias kbd="cd ${KB}"

# -- Init kb-aliases.zsh
function kb_init_aliases () {

    if [[ -f $ZSHBOP_ROOT/kb/kb-aliases.zsh ]]; then
        source $ZSHBOP_ROOT/kb/kb-aliases.zsh
    fi
}

# ===============================================
# -- kb_usage
# -- This function will print out the usage of the kb command
# ===============================================
function kb_usage () {
    _loading "KB Usage"
    echo "Usage: kb [options] <article>"
    echo "Commands:"
    echo "  <article>     The KB article to display"
    echo "  _auto        Auto complete KB articles"
    echo "  list         List all KB articles"
    echo 
    echo "Options:"
    echo "  -c            Use cat instead of md reader"
    echo "  -d            Change to the KB directory"
    echo "  -s            Search for a KB article"
    echo "  -h|--help     Show this help message"
    echo
    echo "Examples:"        
    echo "       kb <article>"
    echo "       kb list"
    echo "       kb -s <search term>"
    echo
}

# ===============================================
# -- kb_list
# -- This function will list all the KB articles
# ===============================================
function kb_list () {
    \ls $ZSH_ROOT/kb
    if [[ -d $ZBC/kb ]]; then				
        _banner_yellow "Current Custom KB Articles"
        \ls $ZBC/kb
    fi   
}

# =============================================================================
# -- kb - A built in knowledge base.
# --
# -- Usage:
# -- kb <article>
# =============================================================================
function kb () {
    _debugf "$funcstack[1] - ${@}"
    
    # -- Ensure KB topics are loaded (lazy loading)
    _kb_ensure_loaded
    
    local zparseopts_error=""
    zparseopts -D -E c=ARG_CAT d=ARG_CD s:=ARG_SEARCH h=ARG_HELP -help=ARG_HELP || zparseopts_error=$?    
    # Handle option parsing errors
    if [[ -n "$zparseopts_error" ]]; then
        _banner_red "Error in command options"
        echo "Option -s requires a search term (e.g., kb -s docker)"
        kb_usage
        return 1
    fi
    _debug "ARG_CAT: $ARG_CAT ARG_CD: $ARG_CD ARG_SEARCH: $ARG_SEARCH ARG_HELP: $ARG_HELP"

    # -- Options
    [[ -n $ARG_HELP ]] && { kb_usage;kb_list;return 0; }
    [[ -n $ARG_CD ]] && cd $ZSHBOP_ROOT/kb
    
    # -- Search
    if [[ -n $ARG_SEARCH ]]; then
        SEARCH_TERM="${ARG_SEARCH[2]}"
        # -- Check if search term is empty
        if [[ -z $SEARCH_TERM ]]; then
            _banner_red "Search term is empty"
            kb_usage
            return 1
        fi                
        _loading "Searching for KB article $SEARCH_TERM"
        kb_search_content $SEARCH_TERM
        return 0
    fi

    # -- Processing <article>    
    ARTICLE="$1"
    kb_set_md_reader
    _loading "KB System Startup"

    # -- Check if kb is set
    if [[ -z $ARTICLE ]]; then
        _warning "No article name specified"
        kb_list
        return 1
    elif [[ $ARTICLE == "_auto" ]]; then
        _debug "Running autocomplete"
        kb_print_topics _auto
    # -- List KB articles.
    elif [[ $ARTICLE == "list" ]]; then
        kb_list
        return 0
    # -- Check if kb file exists
    elif [[ -n $ARTICLE ]]; then
        # -- Check if topic exists
        if [[ -z $kb_topics[$ARTICLE] ]]; then
            _banner_red "KB topic $ARTICLE not found"
            kb_search_content $ARTICLE            
            return 1
        else
            _banner_yellow "Found KB file $kb_topics[$ARTICLE], showing via $MD_READER"
            _debug "Running $MD_READER $kb_topics[$ARTICLE]"
            md-reader $kb_topics[$ARTICLE]
        fi
    # -- Custom KB's    
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
        kb_list
        return 1
    fi
}


# ===============================================
# -- Init kb-topics.zsh
# -- This function will create a multi dimensional array to store all the KB topics
# ===============================================
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

# ===============================================
# -- kb_print_topics
# -- This function will print out all the KB topics in a nice format
# ===============================================
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

# ===============================================
# -- kb_search_title
# -- This function will search for a KB articles title
# ===============================================
function kb_search_title () {
    local KB_SEARCH OUTPUT
    KB_SEARCH="$1"
    _loading3 "Searching for KB article $KB_SEARCH in KB topics"        
    for KB_TOPIC in ${(kon)kb_topics}; do
        if [[ $KB_TOPIC == *$KB_SEARCH* ]]; then
            echo "$KB_TOPIC"
        fi
    done
    _loading3 "Searching in Custom KB topics"
    for KB_TOPIC_CUSTOM in ${(kon)kb_topics_custom}; do
        if [[ $KB_TOPIC_CUSTOM == *$KB_SEARCH* ]]; then
            echo "$KB_TOPIC_CUSTOM"            
        fi
    done
}

# ===============================================
# -- kb_search_content
# -- This function will search for a KB articles content
# ===============================================
fucntion kb_search_content () {
    local KB_SEARCH
    KB_SEARCH="$1"
    _loading3 "Searching for KB article $KB_SEARCH in KB topics"        
    for KB_TOPIC in ${(kon)kb_topics}; do
        if [[ $(grep -E "$KB_SEARCH" $kb_topics[$KB_TOPIC]) ]]; then
            echo "$KB_TOPIC"
        fi
    done
    _loading3 "Searching in Custom KB topics"
    for KB_TOPIC_CUSTOM in ${(kon)kb_topics_custom}; do
        if [[ $(grep -E "$KB_SEARCH" $kb_topics_custom[$KB_TOPIC_CUSTOM]) ]]; then
            echo "$KB_TOPIC_CUSTOM"            
        fi
    done    
}



# ===============================================
# -- kb_set_md_reader
# -- This function will set the MD_READER variable to the best available md reader
# ===============================================
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

# ===============================================
# -- md-reader
# -- This function will read a markdown file and display it in the best available md reader
# ===============================================
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

# ===============================================
# -- md-reader-text
# -- This function will read a markdown text and display it in the best available md reader
# ===============================================
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


# =============================================================================
# -- kb_auto_complete
# -- This function will auto complete the kb command
# =============================================================================
function _kb  {    
    compadd $(kb _auto)
}
compdef _kb kb
