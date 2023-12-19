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
# -- 
# ==================================================
function kb_init_topics () {
    local KB_FILE KB_TOPIC KB_TOPIC_FILE KB_TOPIC_DESC KB_DIRS KB_TAG

    # -- Create multi dimensional array
    typeset -gA kb_topics
    typeset -gA kb_topics_desc
    typeset -gA kb_topics_tag
    typeset -gA kb_topics_dirs

    # -- Check if kb directory exists
    if [[ -d $ZSHBOP_ROOT/kb ]]; then
        kb_topics_dirs[zb]="$ZSHBOP_ROOT/kb"                
        _debug "Found KB directory $ZSHBOP_ROOT/kb"        
    fi

    if [[ -d $ZBC/kb ]]; then
        kb_topics_dirs[zbc]="$ZBC/kb"            
        _debug "Found KB directory $ZBC/kb"
    fi

    # -- Process kb directory array
    for KB_DIR_ID in ${(k)kb_topics_dirs}; do
        KB_DIR=${kb_topics_dirs[$KB_DIR_ID]}        
        _debug "Processing KB directory $KB_DIR"
        # -- Go through all files and create an array
        for KB_FILE in $KB_DIR/*.md; do
            # -- Get the file name and add to array
            KB_TOPIC=$(basename $KB_FILE| sed s/.md//g)
            kb_topics[$KB_TOPIC]=$KB_FILE
            # -- Get Topic Description and add to array
            KB_TOPIC_DESC=$(grep -E '^#\$\$#' $KB_FILE | sed 's/#$$# //g')            
            kb_topics_desc[$KB_TOPIC]=$KB_TOPIC_DESC
            # -- KB Flag                        
            kb_topics_tag[$KB_TOPIC]=$KB_DIR_ID
        done
    done
}

# -- kb -c
function kb_print_topics () {
    local KB_TOPIC KB_OUTPUT OUTPUT_STYLE
    OUTPUT_STYLE=${1:-c}
    # -- Print out all the KB topics and sort
    
    if [[ $OUTPUT_STYLE == "c" ]]; then
        _banner_yellow "KB Topics"
        KB_OUTPUT="Topic\tDescription\n"
        KB_OUTPUT+="-----\t-----------\n"
        for KB_TOPIC in ${(kon)kb_topics}; do
            KB_TOPIC_DESC=${kb_topics_desc[$KB_TOPIC]}
            KB_OUTPUT+="$KB_TOPIC\t${kb_topics_desc[$KB_TOPIC]}\n"
        done
        KB_OUTPUT2="$(_banner_yellow "KB Topics")\n\n"
        KB_OUTPUT2+=$(echo $KB_OUTPUT | column -t -s $'\t')
        echo "$KB_OUTPUT2" | less
    fi        
}

kb_usage () {
    _banner_yellow "Current KB Articles"
    \ls $ZSH_ROOT/kb

    if [[ -d $ZBC/kb ]]; then				
        _banner_yellow "Current Custom KB Articles"
        \ls $ZBC/kb
    fi   
}

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

# -- kb - A built in knowledge base.
kb () {    
    # -- args
    zparseopts -D -E c=CAT
    if [[ -n "$CAT" ]]; then
        echo "Using cat on $1"
        MD_READER="cat"
    fi
    KB=$1

    # -- debug function
    _debug_all

    # -- set md reader
    kb_set_md_reader

    # -- Auto complete KB articles.
    if [[ $KB == "auto" ]]; then
        _debug "Running autocomplete"
        AUTO_KB=()
        if [[ -d $ZSHBOP_ROOT/kb ]] && { ZBR_KBS=$(\ls -1 $ZSHBOP_ROOT/kb); echo $ZBR_KBS | sed s/.md//g; }        
        if [[ -d $ZBC/kb ]] && { ZBC_KBS=$(\ls -1 $ZBC/kb);  echo $ZBC_KBS | sed s/.md//g; }
    # -- List KB articles.
    elif [[ $KB == "list" ]]; then
        kb_usage
        return 0
    # -- Check if kb file exists
    elif [[ -z $KB ]]; then
        kb_usage
            return 1
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
    elif [[ -a $ZSHBOP_ROOT/kb/$1.md ]]; then
        _banner_yellow "Found zshbop KB file $ZSH_ROOT/kb/$1.md, showing via $MD_READER"
        _debug "Running $MD_READER $ZSH_ROOT/kb/$1.md"
        md-reader $ZSH_ROOT/kb/$1.md
    elif [[ -a $ZBC/kb/$1.md ]]; then
        _banner_yellow "Found zshbop custom KB file $ZBC/kb/$1.md, both via $MD_READER"
        _debug "Running $MD_READER $ZBC/kb/$1.md"
        md-reader $ZBC/kb/$1.md        
    else
        kb_usage
            return 1
    fi
}

md-reader () {
    MD_FILE="$1"
    if [[ $MD_READER == "cat" ]]; then
		cat $MD_FILE
	elif [[ $MD_READER == "glow" ]]; then
		eval $MD_READER -p $MD_FILE
	elif [[ $MD_READER == "mdv" ]]; then
		eval $MD_READER $MD_FILE | less
	else
		less $MD_FILE
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
    compadd $(kb auto)
}
compdef _kb kb