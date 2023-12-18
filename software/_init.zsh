# -- Software commands
_debug " -- Loading ${(%):-%N}"
HELP_CATEGORY='software'
help_files[${HELP_CATEGORY}]='Software related commands'
typeset -gA help_software

# --------------------------------------------------
# -- zsh completion
# --------------------------------------------------
function _software() {
  # -- Walk help_software and add to completion
    local -a options
    options=("${(@k)help_software}")

    _values 'software command' $options
}

# --------------------------------------------------
# Associate the _software function with the software command
# --------------------------------------------------
compdef _software software

# --------------------------------------------------
# -- software - Core software command
# --------------------------------------------------
function software () {
	_debug_all "$@"
	if [[ -z $1 ]]; then
		help software
	elif [[ -n $1 ]]; then
		_loading "Installing software $1"
		_debug "Running command software_$1"		
		run_software="software_$1"
		# check if function exists
		if _cmd_exists $run_software; then
			_debug "\$run_software = $run_software"
			$run_software $@
		else
			_error "Software $1 not found"
		fi
	fi
}
# --------------------------------------------------
# -- _software_chmod
# --------------------------------------------------
function _software_chmod () {
	_debug "Setting chmod 755 on $1"
	chmod 755 $1
}

# --------------------------------------------------
# -- _software_install $CMD $URL
# --------------------------------------------------
function _software_install () {
	local CMD=$1 URL=$2
	# -- Check if software exists
	_debug "Checking if $CMD exists"
	if _cmd_exists $CMD; then
		_notice "$CMD already installed"
	else
		_loading3 "Installing $CMD to $ZSHBOP_SOFTWARE_PATH"		
		curl -s $URL -o $ZSHBOP_SOFTWARE_PATH/$CMD
		_software_chmod $ZSHBOP_SOFTWARE_PATH/$CMD
		_success "$CMD installed"
	fi
}

# ===================================================