# -----------
# kb function
# -----------
# -- kb - A built in knowledge base.
kb () {
        _debug_function
        
        KB=$1
       
        # -- Check if mdv exists if not use cat
        _debug "Checking if mdv exists"
		_cexists mdv
        if [[ $? == "0" ]]; then
                _debug "mdv exists!"
                MD_READER=mdv
        else
                _debug "mdv doesn't exist using cat"
                MD_READER=cat
        fi
        _debug "MD_READER: $MD_READER"

		# -- Check if kb file exists
		if [[ -a $ZSHBOP_ROOT/kb/${KB}.md ]] && [[ -a $ZBC/kb/${KB}.md ]]; then
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
				echo $KB_COMBINED | $MD_READER - | less
        elif [[ -a $ZSHBOP_ROOT/kb/$1.md ]]; then
				_banner_yellow "Found zshbop KB file $ZSH_ROOT/kb/$1.md, showing both via $MD_READER"
                $MD_READER $ZSH_ROOT/kb/$1.md | less
        elif [[ -a $ZBC/kb/$1.md ]]; then
        		_banner_yellow "Found zshbop custom KB file $ZBC/kb/$1.md, showing both via $MD_READER"
        		$MD_READER $ZBC/kb/$1.md | less
		else
				_error "Couldn't find $KB in KB"
				_banner_yellow "Current KB Articles"
                \ls $ZSH_ROOT/kb

				if [[ -d $ZBC/kb ]]; then				
					_banner_yellow "Current Custom KB Articles"
        	        \ls $ZBC/kb
        	    fi
                return 1
        fi

		# -- alert to install mdv for better experience
        if [[ $MD_READER == cat ]]; then
                echo "\n\n"
                echo "---------------------------------------"
                echo "mdv not avaialble failing back to cat"
                echo "trying installing mdv by typing"
                echo "---------------------------------------"
        fi
}
