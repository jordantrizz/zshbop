#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- kb.zsh -- Knowledge Base (KB) functions
# -----------------------------------------------------------------------------------
_debug_load

# -- kbc
alias kbc="kb -c"
alias kbd="cd ${KB}"

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