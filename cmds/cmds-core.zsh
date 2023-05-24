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

# -- kb
help_core[kb]='knowledge base'

# - Don't know what cmd was for?
cmd () { }; help_core[cmd]='broken and needs to be fixed'

# -- paths
help_core[paths]='print out \$PATH on new lines'
paths () {
	echo ${PATH:gs/:/\\n}
}

# -- add-path
help_core[add-path]='Add to $PATH'
add-path () {
	if [[ -z $1 ]]; then
		echo "Usage: add-path <path>"
		return 1
	else
		export PATH=$PATH:$@
	fi
}

# -- env-install - Install tools into environment.
help_core[env-install]='Install tools into environment'
env-install () {
	sudo apt-get update
    echo "---------------------------"
    echo "Installing default tools.."
    echo "---------------------------"
    echo "DEFAULT_TOOLS: $DEFAULT_TOOLS"
    
    if read -q "Continue? (y/n)"; then
	    sudo apt-get install --no-install-recommends postfix- $DEFAULT_TOOLS
    else
		echo "Skipping due to press 'n'"
    fi
    echo ""
    
    
    
    echo "---------------------------"
    echo "Installing extra tools.."
    echo "---------------------------"
	echo "extra_tools: $extra_tools"
    
        if read -q "Continue? (y/n)"; then
		sudo apt-get install --no-install-recommends postfix- $extra_tools
    else
        echo "Skipping due to press 'n'"
    fi
    echo ""
    
    echo "---------------------------"
    echo "Manual installs"
    echo "---------------------------"
    echo " mdv       - pip install mdv"
    echo " gnomon    - via npm"
    echo " lsd       - https://github.com/Peltoche/lsd"
    echo ""
}

# -- install-pkg - Install specific tool
# TODO - why does this exist?
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

	if [[ -n $1 ]]; then
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
help_files[$1]='Software related commands'

TEMPLATE
	fi

}

# -- kbe
help_core[kbe]='Edit a KB with $EDITOR'
kbe () {
        _debug "\$EDITOR is $EDITOR and \$EDITOR_RUN is $EDITOR_RUN"
	if [[ -n $1 ]]; then
		${=EDITOR_RUN} $ZSHBOP_ROOT/kb/$1.md
	else
		echo "Usage: $funcstack <name of KB>"
	fi
}

# -- ce
help_core[cmde]='Edit a cmd file with $EDITOR'
cmde () {
        _debug "\$EDITOR is $EDITOR and \$EDITOR_RUN is $EDITOR_RUN"
        if [[ -z $1 ]]; then
                ${=EDITOR_RUN} $ZSHBOP_ROOT/cmds/cmds-$1.zshrc
        else
                echo "Usage: $funcstack[1] <name of command file>"
        fi
}

# -- ce
help_core[ce]='Edit core files'
ce () {
        _debug "\$EDITOR is $EDITOR and \$EDITOR_RUN is $EDITOR_RUN"
        if [[ -z $1 ]]; then
                ${=EDITOR_RUN} $ZSHBOP_ROOT/$1.zshrc
        else
                echo "Usage: $funcstack[1] <name of core file>"
        fi
}


# -- rename-ext
help_core[rename-ext]='Rename file extensions'
rename-ext () {
        if [[ -z $1 ]] || [[ -z $2 ]]; then
	        echo "Usage: rename-ext <old extension> <new extension>"
        else
                for f in *.$1; do
                        #echo "mv -- \"$f\" \"${f%.$1}.$2\""
                        mv -- "$f" "${f%.$1}.$2"
                done
        fi
}

# -- zshbop install
help_core[zshbop-install]='zshbop install command'
zshbop-install () {
	echo "bash <(curl -sL https://zshrc.pl)"
}

# -- os-alias - return alias if binary exists for os
# TODO find other commands and use os-binary such as glint
help_core[os-alias]='Return alias if binary exists for os'
os-binary () {
    BINARY="$1"
    local OS_BINARY_TAG=""
	unset LC_CHECK NULL OS_BINARY
	_debug "Running $MACHINE_OS"
	
	if [[ $MACHINE_OS == "linux" ]]; then
		_debug "Detected OS linux"
		OS_BINARY_TAG="linux_x86_64"
	elif [[ $MACHINE_OS == "mac" ]]; then
		_debug "Detected OS mac"
		OS_BINARY_TAG="mac_x86_64"
	else
		_debug "Can't detect OS \$MACHINE_OS = $MACHINE_OS"
		_error "No binary available for $BINARY on $MACHINE_OS"
		return 1
	fi	
	
	OS_BINARY="${BINARY}-${OS_BINARY_TAG}"
	_debug "OS_BINARY: $OS_BINARY"	
	_cexists ${OS_BINARY}
	
	if [[ $? == "1" ]]; then
		_debug "$OS_BINARY not installed"
		return 1
	else
	    _debug "Using created alias ${BINARY} ${OS_BINARY}"
	    eval "function ${BINARY} () { ${OS_BINARY} \$@ }"
        eval "export ${(U)BINARY}_CMD=$OS_BINARY"
	    return 0
	fi
}

# -- debugz - return alias if binary exists for os
help_core[debugz]='Debug ZSH Function'
function debugz() {
  local func_name="$1"
  shift

  PS4='+ ${FUNCNAME[0]}: line %l: '
  set -x
  $func_name "$@"
  set +x
}

# -- os - return os
help_core[os]='Return OS'
function os() {
  echo "$MACHINE_OS / $MACHINE_OS_FLAVOUR"
}