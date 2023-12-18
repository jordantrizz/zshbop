# -- install-pkg - Install specific tool
# TODO - why does this exist?
#help_core[install-pkg]='Install specific tool'
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
        _cmd_exists $INSTALL_CMD[1]

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