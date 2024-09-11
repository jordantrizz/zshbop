# ====================================================================================================
# -- download based installs
# ====================================================================================================

# -- software_gh-cli-curl
help_software[gh-cli-curl]="Install github cli"
software_gh-cli-curl () {
	VERSION=`curl  "https://api.github.com/repos/cli/cli/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c2-`
	curl -sSL https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_amd64.tar.gz -o $HOME/tmp/gh_${VERSION}_linux_amd64.tar.gz
	cd $HOME/tmp
	tar xvf gh_${VERSION}_linux_amd64.tar.gz
	cp $HOME/tmp/gh_${VERSION}_linux_amd64/bin/gh $ZSHBOP_SOFTWARE_PATH
	_software_chmod $ZSHBOP_SOFTWARE_PATH/gh
}

# --------------------------------------------------
# -- software_speedtest-cli
# --------------------------------------------------
help_software[speedtest-cli]="Speedtest-cli from https://github.com/sivel/speedtest-cli"
software_speedtest-cli () {
    wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
    _software_chmod speedtest-cli
    sed -i 's/env python$/env python3/g' $ZSHBOP_SOFTWARE_PATH/speedtest-cli
}

# --------------------------------------------------
# -- vt
# --------------------------------------------------
help_software[vt]="Virus Total CLI"
if [[ $MACHINE_OS == "linux" ]] || [[ $MACHINE_OS == "wsl" ]]; then
	_cmd_exists vt-linux64
	[[ $? -ge "0" ]] && alias vt=vt-linux64 || alias vt="echo 'VT not installed'"
elif [[ $MACHINE_OS == "mac" ]]; then
	_cmd_exists vt-macos
	[[ $? -ge "0" ]] && alias vt=vt-macos || alias vt="echo 'VT not installed'"
fi
software_vt () {
	echo "No install method for vt"
}

# --------------------------------------------------
# -- b2
# --------------------------------------------------
help_software[b2]="Backblaze CLI"
if [[ $MACHINE_OS == "linux" ]] || [[ $MACHINE_OS == "wsl" ]]; then
	_cmd_exists b2-linux
    [[ $? -ge "1" ]] && alias b2=b2_download || alias b2=b2-linux
elif [[ $MACHINE_OS == "mac" ]]; then
	_cmd_exists b2-darwin
    [[ $? -ge "1" ]] && alias b2=b2_download || alias b2=b2-darwin
fi
b2_download () {
	_debug_all
	echo "b2 not found, downloading"
	# -- linux
	if [[ $MACHINE_OS == "linux" ]] || [[ $MACHINE_OS == "wsl" ]]; then
		echo "Detected linux OS."
        if [[ -f $ZSHBOP_SOFTWARE_PATH/b2-linux ]]; then
			alias b2=b2-linux
		else
			_debug "No b2-linux binary, downloading b2-linux from github to $ZSHBOP_SOFTWARE_PATH"
			wget -O $ZSHBOP_SOFTWARE_PATH/b2-linux https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux
			_software_chmod $ZSHBOP_SOFTWARE_PATH/b2-linux
			if [[ $? -ge 1 ]]; then
				_error "Download failed."
			else
				_success "b2-linux downloaded to $ZSHBOP_SOFTWARE_PATH, run the b2 command"
				alias b2=b2-linux
			fi
		fi
	# -- mac
	elif [[ $MACHINE_OS == "mac" ]]; then
		if [[ $ZSHBOP_SOFTWARE_PATH/b2-darwin ]]; then
			alias b2=b2-darwin
		else
			_debug "No b2-darwin binary, downloading b2-linux from github to $ZSHBOP_SOFTWARE_PATH"
			wget -O $ZSHBOP_SOFTWARE_PATH/b2-darwin https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-darwin
			if [[ $? -eg 1 ]]; then
   	            _error "Download failed."
	        else
		        _success "b2-darwin downloaded to $ZSHBOP_SOFTWARE_PATH, run the b2 command"
		        alias b2=b2-darwin
        	fi
		fi
	fi
}

# --------------------------------------------------
# -- aws-cli
# --------------------------------------------------
help_software[aws-cli]="Install aws-cli"
software_aws-cli () {
	if [[ ! -d $HOME/downlods ]]; then
		mkdir $HOME/downloads
	fi
	cd $HOME/downloads
	curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscli-exe-linux-x86_64.zip
	unzip awscli-exe-linux-x86_64.zip
	cd $HOME/downloads/aws
	./install -i $ZSHBOP_SOFTWARE_PATH/aws-cli -b $ZSHBOP_SOFTWARE_PATH --update
}

# ====================================================================================================
# -- glint
# ====================================================================================================
help_software[glint]="Install glint - https://github.com/brigand/glint"
function _detect_glint_os () {
	# Check if glint is already installed
	if _cmd_exists glint; then
		_log "Found glint, setting up alias"
		GLINT_INSTALLED="1"
		return 0
	fi
	
	# Check for glint-linux
	if [[ $MACHINE_OS == "linux" ]]; then
		_debug "Check for glint-linux under $MACHINE_OS"    
		if _cmd_exists glint-linux; then
			_log "Found glint-linux, setting up alias"
			GLINT_INSTALLED="1"
			alias glint=glint-linux			
		else
			_cmd_exists glint-linux        
			_warning "glint-linux not found in $MACHINE_OS"			
		fi
	elif [[ $MACHINE_OS == "mac" ]]; then
		if [[ $MACHINE_OS2 == "mac-intel" ]]; then
			# Check if we have glint-macos
			if _cmd_exists glint-macos; then
				_log "Found glint-macos, setting up alias"
				GLINT_INSTALLED="1"
				alias glint=glint-macos				
			else				
				_warning "glint-macos not found in $MACHINE_OS/$MACHINE_OS2"
			fi			
		elif [[ $MACHINE_OS2 == "mac-arm" ]]; then
			_warning "glint not found in $MACHINE_OS/$MACHINE_OS2"			
		fi
	else
		_debug "Couldn't detect OS for glint"
	fi
}
_detect_glint_os

software_glint () {
	# Check if glint is already installed
	if [[ $GLINT_INSTALLED == "1" ]]; then
		_log "glint already installed"
		return 0
	fi

	# Start install for glint.	
	if [[ $MACHINE_OS == "linux" ]]; then		
		_loading "Installing glint in $ZSHBOP_SOFTWARE_PATH"					
		curl -L -o $ZSHBOP_SOFTWARE_PATH/glint-linux https://github.com/brigand/glint/releases/download/v6.3.4/glint-linux
		_software_chmod $ZSHBOP_SOFTWARE_PATH/glint-linux
		_loading3 "Reload shell"
	elif [[ $MACHINE_OS == "mac" ]]; then
		if [[ $MACHINE_OS2 == "mac-intel" ]]; then			
			_loading "Installing glint for $MAC_OS2 in $ZSHBOP_SOFTWARE_PATH"
			curl -L -o $ZSHBOP_SOFTWARE_PATH/glint-macos https://github.com/brigand/glint/releases/download/v6.3.4/glint-macos
			_software_chmod $ZSHBOP_SOFTWARE_PATH/glint-macos
			_loading3 "Reload shell"
		elif [[ $MACHINE_OS2 == "mac-arm" ]]; then
			# Ensure we have cargo in the path
			if _cmd_exists cargo; then
				_loading "Installing glint for $MAC_OS2 in $ZSHBOP_SOFTWARE_PATH"
				cargo install glint
			else
				_error "Cargo not found, please install cargo/rust first"
			fi
		fi 
	else
    	_debug "Couldn't detect OS for glint"
	fi
}

# --------------------------------------------------
# -- change
# --------------------------------------------------
help_software[change]="Install change - https://raw.githubusercontent.com/adamtabrams/change"
software_change () {
	_software_install change "https://raw.githubusercontent.com/adamtabrams/change/master/change"
}

# ===============================================
# -- software_eza
# ===============================================
help_software[eza]="Install eza"
software_eza () {
	_cmd_exists nix
	if [[ $? -ge 1 ]]; then
		_error "Nix not found, please install nix first"
		return 1
	fi
	nix profile install nixpkgs#eza
}

# ===============================================
# -- software_vhwinfo
# ===============================================
help_software[vhwinfo]='Temporarily downloads vhwinfo and displays system information.'
vhwinfo () {
        echo " -- Downloading vhwinfo.sh via wget and running"
        wget --no-check-certificate https://github.com/rafa3d/vHWINFO/raw/master/vhwinfo.sh -O - -o /dev/null|bash
}