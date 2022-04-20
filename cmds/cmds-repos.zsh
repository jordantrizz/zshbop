# --
# Core commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# -- repos - Install popular github.com Repositories
help_core[repos]='Install popular github.com repositories.'

repos () {
	# debug
	_debug_all $@

	# list of repositories
        declare -A GIT_REPOS GIT_REPOS_URL
        GIT_REPOS[gp-tools]="GridPane Tools by @Jordantrizz"
        GIT_REPOS_URL[gp-tools]="https://github.com/jordantrizz/gp-tools"
	GIT_REPOS[github-markdown-toc]="Add markdown table of contents to README.md"
        GIT_REPOS_URL[github-markdown-toc]="https://github.com/jordantrizz/github-markdown-toc"
	GIT_REPOS[cloudflare-cli]="Interface with Cloudflares API"
        GIT_REPOS_URL[cloudflare-cli]="https://github.com/jordantrizz/cloudflare-cli"
	GIT_REPOS[site24x7-custom-install]="Custom Site24x7 install"
        GIT_REPOS_URL[site24x7-custom-install]="https://github.com/lmtca/site24x7-custom-install"
        GIT_REPOS[forwardemail-api-bash]="forwardemail.net api bash script"
        GIT_REPOS_URL[forwardemail-api-bash]="https://github.com/jordantrizz/forwardemail-api-bash"
        
        if [[ $1 == 'install' ]] && [[ -n "$2" ]]; then
		_debug "Checking if $2 is in \$GIT_REPO"
        	_if_marray "$2" GIT_REPOS
        	REPODIR=$2
        	
		if [[ $MARRAY_VALID == "0" ]]; then
			_debug "Found repository - installing via url ${GIT_REPOS_URL[$2]}"
	                echo "-- Installing repository $2 into $ZSHBOP_ROOT/repos/$REPODIR"
			if [[ ! -d "$ZSHBOP_ROOT/repos/$REPODIR" ]]; then
				git -C $ZSHBOP_ROOT/repos clone ${GIT_REPOS_URL[$2]}
				init_path
			else
				_error "Repo already installed or $ZSHBOP_ROOT/repos/$REPODIR folder exists..exiting"
			fi
		else
			echo "No such repository $2"
		fi
		return
        elif [[ $1 == 'update' ]]; then
        	echo "-- Updating repos "
		if [ "$(find "$ZSHBOP_ROOT/repos" -mindepth 1 -maxdepth 1 -not -name '.*')" ]; then
			_debug "Found repositories"
			for name in $ZSHBOP_ROOT/repos/*; do
		                _debug "Found $name"
	        	        if [[ -d $name ]]; then
	        	                echo "  -- Updating repo $name"
	                	        git -C $name pull
		                else
		                        echo "  -- No repos to update"
	       		        fi
		        done
		else
			echo "  -- No repos to update"
		fi
        else
                echo "Usage: repos <install|update>"
                echo ""
                echo "This command pulls down popular Github repositories."
                echo ""
                echo "To pull down a repo, simply type \"repo <reponame>\" and the repository will be installed into ZSHBOP/repos"
                echo ""
                echo "Repositories"
                echo ""
                for key value in ${(kv)GIT_REPOS}; do
                        printf '%s\n' "  ${(r:60:)key} - $value"
                done
                echo ""
	fi
}

# -- help-template
help_core[help-template]='Create help template'
help-template () {
	help_template_file=$ZSHBOP_ROOT/cmds/cmds-$1.zshrc
	if [[ -z $1 ]]; then
		echo "-- Provide a name for the new help file"
	elif [[ -f $help_template_file ]]; then
		echo "-- File exists $help_template_file, exiting."
	else
		echo "-- Writting cmds file $help_template_file"
cat > $help_template_file <<TEMPLATE
# --
# $1 commands
#
# Example help: help_$1[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading \${(%):-%N}"

# - Init help array
typeset -gA help_$1

# What help file is this?
help_files[$1_description]="-- To install, run software <cmd>"
help_files[$1]='Software related commands'

TEMPLATE
	fi

}

# -- kbe
help_core[kbe]='Edit a KB with $EDITOR'
kbe () {
        _debug "\$EDITOR is $EDITOR and \$EDITOR_RUN is $EDITOR_RUN"
	if [[ $1 ]]; then
		${=EDITOR_RUN} $ZSHBOP_ROOT/kb/$1.md
	else
		echo "Usage: $funcstack <name of KB>"
	fi
}

# -- ce
help_core[cmde]='Edit a cmd file with $EDITOR'
cmde () {
        _debug "\$EDITOR is $EDITOR and \$EDITOR_RUN is $EDITOR_RUN"
        if [[ $1 ]]; then        
                ${=EDITOR_RUN} $ZSHBOP_ROOT/cmds/cmds-$1.zshrc
        else
                echo "Usage: $funcstack[1] <name of command file>"
        fi
}

# -- he
help_core[ce]='Edit core files'
ce () {
        _debug "\$EDITOR is $EDITOR and \$EDITOR_RUN is $EDITOR_RUN"
        if [[ $1 ]]; then
                ${=EDITOR_RUN} $ZSHBOP_ROOT/$1.zshrc
        else
                echo "Usage: $funcstack[1] <name of core file>"
        fi
}