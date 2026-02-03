# =============================================================================
# tool commands
# =============================================================================
_debug " -- Loading ${(%):-%N}"
typeset -gA help_tools

# What help file is this?
help_files[tools]='Recommended linux tools'

# ===============================================
# -- needrestart - check if system needs a restart
# ===============================================
help_linux[needrestart]='Check if system needs a restart'
_cmd_exists needrestart
if [[ $? == "1" ]]; then
    _log "needrestart not installed"
	needrestart () {
		_debug "needrestart not installed"
		_notice "needrestart not installed"
		echo 'Press any key to install needrestart...'; read -k1 -s
		sudo apt-get install needrestart
	}
fi

# ===============================================
# -- doge
# ===============================================
help_linux[doge]='doge a replacement for dig'
_cmd_exists doge
if [[ $? == "1" ]]; then
    _log "doge not installed"
    doge () {
        _debug "doge not installed"
        _notice "doge not installed"
        echo 'Press any key to install doge...'; read -k1 -s
        _cmd_exists cargo
        if [[ $? == "1" ]]; then
            _error "cargo not installed"
            return 1
        else
            cargo install dns-doge
            unset -f doge
        fi
    }
fi

# ===============================================
# -- broot
# ===============================================
help_linux[broot]='Get an overview of a directory, even a big one'
_cmd_exists broot
if [[ $? == "1" ]]; then
	function broot () {
		check_broot
	}
	function check_broot () {
		_log "broot not installed"
	}
fi

# =============================================================================
# -- geekbench-run
# =============================================================================
help_tools[geekbench-run]='Run geekbench'
geekbench-run () {
	# Download geekbench
	_loading "Downloading geekbench"
	DOWNLOAD_URL=$(wget -qO- https://www.geekbench.com/download/linux/ | sed -n "s/.*URL=\([^']*\).*/\1/p")
	wget -O /tmp/Geekbench-6.3.0-Linux.tar.gz "$DOWNLOAD_URL"

	# Extract geekbench
	_loading "Extracting geekbench"
	tar -xvf /tmp/Geekbench-6.3.0-Linux.tar.gz -C /tmp

	# Run geekbench
	_loading "Running geekbench"
	/tmp/Geekbench-6.3.0-Linux/geekbench_x86_64
}

# ===============================================
# -- geekbench-run-oneliner
# ===============================================
help_tools[geekbench-install]='Print out oneliner to download, and run geekbench'
geekbench-install () {
    echo 'cd /tmp && wget -O Geekbench.tar.gz "$(wget -qO- https://www.geekbench.com/download/linux/ | sed -n "s/.*URL=\([^'\'']*\).*/\1/p")" && tar -xzf Geekbench.tar.gz && ./Geekbench-6.3.0-Linux/geekbench6'
}

