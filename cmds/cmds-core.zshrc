# --
# Core commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[core]='Core commands'

# - Init help array
typeset -gA help_core

# - Don't know what cmd was for?
cmd () { }; help_core[cmd]='broken and needs to be fixed'

# -- paths
help_core[paths]='print out \$PATH on new lines'
paths () {
	echo ${PATH:gs/:/\\n}
}

# -- kb - A built in knowledge base.
help_core[kb]='knowledge base'
kb () {
	_debug_function
        #-- Check if mdv exists if not use cat
        if [[ $(_cexists mdv) ]]; then
                mdv_reader=mdv
        else
                mdv_reader=less
        fi
        _debug "mdv_reader: $mdv_reader"

        if [[ -a $ZSH_ROOT/kb/$1.md ]]; then
                echo "Opening $ZSH_ROOT/kb/$1.md"
                $mdv_reader $ZSH_ROOT/kb/$1.md
        else
                ls -l $ZSH_ROOT/kb
        fi
        if [[ $mdv_reader == cat ]]; then
                echo "\n\n"
                echo "---------------------------------------"
                echo "mdv not avaialble failing back to cat"
                echo "trying installing mdv by typing"
                echo "---------------------------------------"
        fi
}

# -- checkenv - Check Environment for installed software
help_core[env-check]='check environment for installed software and tools'
env-check () {
        echo "---------------------------"
        echo "Looking for default tools.."
        echo "---------------------------"
        echo ""
        for i in $default_tools; do
                if _cexists $i; then
                        echo "$i is $bg[green]$fg[white] INSTALLED. $reset_color"
                else
                        echo "$i is $bg[red]$fg[white] MISSING. $reset_color"
                fi
        done
        echo "---------------------------"
        echo "Looking for default tools.."
        echo "---------------------------"
        echo ""
        for i in $extra_tools; do
        if _cexists $i; then
                        echo "$i is $bg[green]$fg[white] INSTALLED. $reset_color"
                else
                        echo "$i is $bg[red]$fg[white] MISSING. $reset_color"
        fi
        done
        echo "--------------------------------------------"
        echo "Run env-install to install above tools"
        echo "--------------------------------------------"

}

# -- env-install - Install tools into environment.
help_core[env-install]='Install tools into environment'
env-install () {
        echo "---------------------------"
        echo "Installing default tools.."
        echo "---------------------------"
        _debug "default_tools: $default_tools"
        sudo apt-get update
        sudo apt install $default_tools
        echo "---------------------------"
        echo "Installing extra tools.."
        echo "---------------------------"
	_debug "extra_tools: $extra_tools"
        sudo apt install $extra_tools
        echo "---------------------------"
        echo "Manual installs"
        echo "---------------------------"
        echo " mdv       - pip install mdv"
        echo " gnomon    - via npm"
        echo " lsd       - https://github.com/Peltoche/lsd"
        echo ""
}

# -- install-pkg - Install specific tool
help_core[install-pkg]='Install specific tool'
install-pkg () {
	# List of packages.
	typeset -gA pkg
	typeset -gA pkg_info

	pkg[dt]='go install github.com/42wim/dt'
	pkg_info[dt]='DNS tool that displays information about your domain.'

	pkg[broot]="$PKG_MANAGER broot"
	pkg_info[broot]='Get an overview of a directory, even a big one'

	# Check if we have go or apt installed?
        _debug "pkg: $pkg[$1]"
        # Get install command and confirm it's available
        INSTALL_CMD=(${=pkg[$1]})
        _debug "First command: $INSTALL_CMD[1]"
        _debug "Checking if $INSTALL_CMD[1] exist?"
        _cexists $INSTALL_CMD[1]

        # If using go.
        if [[ $INSTALL_CMD[1] == "go" ]]; then
        	_debug "Using go, checking version"
        	GO_VER=$(go version | { read _ _ v _; echo ${v#go}; })
        	GO_VER=${GO_VER%.*}
		_debug "go_ver: $GO_VER"
        	if (( $(echo "$GO_VER <= 1.17" | bc -l) )); then
        		_debug "go <= 1.17, updating command"
        		_debug "go get $INSTALL_CMD[3];$INSTALL_CMD"
        		INSTALL_CMD="go get $INSTALL_CMD[3];$INSTALL_CMD"
		else
			_debug "go <= than 1.17, proceeding"
		fi
	fi
	# Main
	if [[ $1 ]]; then
		if [[ $CMD_EXISTS == "0" ]]; then
			_debug "$INSTALL_CMD[1] exists"
			echo "-- Installing using command: $INSTALL_CMD"
			eval $INSTALL_CMD
		else
			_debug "$INSTALL_CMD[1] doesn't exist"
			echo "  -- Missing \"$INSTALL_CMD[1]\" can't install package, run env-check"
		fi
	else
		echo "Usage: install-pkg <package>"
		echo ""
		echo "Packages available"
	        for key in ${(kon)pkg}; do
        	        printf '%s\n' "  ${(r:25:)key} - $pkg_info[$key]"
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

# -- ce
help_core[ce]='Edit core files'
ce () {
        _debug "\$EDITOR is $EDITOR and \$EDITOR_RUN is $EDITOR_RUN"
        if [[ $1 ]]; then
                ${=EDITOR_RUN} $ZSHBOP_ROOT/$1.zshrc
        else
                echo "Usage: $funcstack[1] <name of core file>"
        fi
}


# -- rename-ext
help_core[rename-ext]='Rename file extensions'
rename-ext () {
        if [[ ! $1 ]] || [[ ! $2 ]]; then
        echo "Usage: rename-ext <old extension> <new extension>"
        else
                for f in *.$1; do
                        #echo "mv -- \"$f\" \"${f%.$1}.$2\""
                        mv -- "$f" "${f%.$1}.$2"
                done
        fi
}