# ====================================================================================================
# -- system installer based software
# ====================================================================================================

# --------------------------------------------------
# -- smtp-cli - installs smtp-cli
# --------------------------------------------------
help_software[smtp-cli]='Installs required packages for smtp-cli'
software_smtp-cli () {
	echo "  -- Installing smtp-cli required packages"
	sudo apt install libio-socket-ssl-perl libdigest-hmac-perl libterm-readkey-perl libmime-lite-perl libfile-libmagic-perl libio-socket-inet6-perl libnet-dns-perl
}

# --------------------------------------------------
# -- php-install
# --------------------------------------------------
help_software[php-install]="One liner for PHP package install"
php-install () {
	_loading "For Remi on CentOS"
	echo "yum install php74-{php-recode,php-snmp,php-pecl-apcu,php-ldap,php-pecl-memcached,php-imap,php-odbc,php-xmlrpc,php-intl,php-process,php-pecl-igbinary,php-pear,php-pecl-imagick,php-tidy,php-pspell,php-pdo,php-pecl-mcrypt,php-soap,php-mbstring,php-mysqli}"
	_loading "For Ubuntu"
	echo "apt-get install php74-{mbstring,mysql}"
	_loading "For Ubuntu and Litespeed"
	echo "apt-get install -f lsphp81-{snmp,ldap,imap,intl,tidy,pspell,mysql,redis,igbinary,opcache,curl,imagick,memcached,msgpack}"
}


# --------------------------------------------------
# -- gp-apt
# --------------------------------------------------
help_software[gp-apt]="Common apps for GridPane Servers"
gp-apt () {
	apt-get install ncdu
}


# --------------------------------------------------
# -- my-cli
# --------------------------------------------------
help_software[mycli]="MySQL CLI Helper with auto complete"
_cmd_exists mycli
if [[ $? -ge "1" ]]; then
	alias mycli=mycli_install
fi
mycli_install () {
	_notice "mycli not installed, installing"
    sudo apt-get install mycli
}


# --------------------------------------------------
# -- nala
# --------------------------------------------------
help_software[nala]='apt replacement for Ubuntu and Debian'
software_nala () {
	echo "-- Setting up nala"
	sudo echo "deb [arch=amd64,arm64,armhf] http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
	sudo wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
	sudo apt update && sudo apt install nala
}

# --------------------------------------------------
# -- nrich
# --------------------------------------------------
help_software[nrich]='Install nrich'
software_nrich () {
    echo "-- Setting up atop"
    sudo wget -P /tmp https://gitlab.com/api/v4/projects/33695681/packages/generic/nrich/latest/nrich_latest_amd64.deb
	sudo apt-get install /tmp/nrich_latest_amd64.deb
}

# --------------------------------------------------
# -- atop
# --------------------------------------------------
help_software[atop]='Install atop and configure'
software_atop () {	
	if [[ -z $2 ]]; then
		_notice "Missing interval using default 300 seconds"
		INTERVAL=300		
	else
		INTERVAL=$2
	fi
	
	_loading "Installing and Setting up atop top run every $INTERVAL seconds"
	
	_loading2 "Installing atop"
	if _cmd_exists atop; then
		_notice "atop already installed"		
	else
		_loading3 "Installing atop"
		sudo apt-get install atop
	fi

	_loading2 "Setting up atop with interval $INTERVAL"
	sudo sed -i -e 's/INTERVAL=600/INTERVAL=300/g' /usr/share/atop/atop.daily
	
	_loading2 "Restarting atop"
	sudo systemctl restart atop
	sudo systemctl enable atop
}

# --------------------------------------------------
# -- mdv - Installs terminal markdown viewer
# --------------------------------------------------
help_software[mdv]='Installs terminal markdown viewer (pip install mdv)'
software_mdv () {
	pip install mdv
}

# --------------------------------------------------
# -- asciinema - Installs asciinema
# --------------------------------------------------
help_software[asciinema]='Installs asciinema'
software_asciinema () {
	sudo apt-get install asciinema
}

# --------------------------------------------------
# -- bat
# --------------------------------------------------
help_software[bat]="Install bat"
function bat() {
    _loading "Installing bat"
    if [[ $MACHINE_OS == "mac" ]]; then
        brew install bat
    elif [[ $MACHINE_OS == "linux" ]]; then
        sudo apt install bat
    fi
}

# --------------------------------------------------
# -- github-cli - Installs github.com CLI
# --------------------------------------------------
help_software[gh-cli-deb]='Installs github.com cli, aka gh'
software_gh-cli-deb () {
	type -p curl >/dev/null || sudo apt install curl -y
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
}


# --------------------------------------------------
# -- powershell
# --------------------------------------------------
help_software[powershell]="Powershell for Linux"
_cmd_exists pwsh
[[ $? -ge "1" ]] && alias pwsh=software_powershell || alias pwsh=pwsh

software_powershell () {
	if [[ $MACHINE_OS == "mac" ]]; then
		echo "Installing Powershell on Mac using brew"
		brew install --cask powershell
	else
		echo "Installing Powershell on Ubuntu"
		# Update the list of packages
		sudo apt-get update
		# Install pre-requisite packages.
		sudo apt-get install -y wget apt-transport-https software-properties-common
		# Download the Microsoft repository GPG keys
		wget -q -O $TMP/packages-microsoft-prod.deb "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
		# Register the Microsoft repository GPG keys
		sudo dpkg -i $TMP/packages-microsoft-prod.deb
		# Update the list of packages after we added packages.microsoft.com
		sudo apt-get update
		# Install PowerShell
		sudo apt-get install -y powershell
	fi
}

# --------------------------------------------------
# -- ncdu
# --------------------------------------------------
help_software[ncdu]="Install ncdu"
_cmd_exists ncdu
if [[ $? == "1" ]]; then
    function ncdu () {
        if [[ $MACHINE_OS == "mac" ]]; then
            brew install ncdu
        elif [[ $MACHINE_OS == "linux" ]]; then
            sudo apt install ncdu
        fi
		unset -f ncdu
    }
fi

# --------------------------------------------------
# -- php-relay
# --------------------------------------------------
help_software[php-relay]="Install php-relay"
function php-relay () {
    _loading "Installing php-relay"
    _loading3 "Adding repo to apt"
    curl -s https://repos.r2.relay.so/key.gpg | sudo apt-key add -
    sudo add-apt-repository "deb https://repos.r2.relay.so/deb $(lsb_release -cs) main"
    sudo apt update
    _loading3 "Installing php-relay package"
    sudo apt install php-relay
    _success "Installed php-relay default PHP vesion"
    echo "Other versions can be installed with 'apt-get install php8.1-relay'"
    echo "Litespeed or Openlitespeed servers need additional configuration see kb php-relay.md"
}

# --------------------------------------------------
# -- pie
# --------------------------------------------------
help_software[pie]="Install PHP pie (Package Installer for Extensions)"
function software_pie () {
    _loading "Installing pie dependencies"
    sudo apt install -y gcc make autoconf libtool bison re2c pkg-config php-dev
    
    _loading3 "Downloading pie.phar"
    sudo curl -L -o /usr/local/bin/pie https://github.com/php/pie/releases/download/1.3.7/pie.phar
    
    _loading3 "Making pie executable"
    sudo chmod +x /usr/local/bin/pie
    
    _success "pie installed successfully"
    pie --version
}

# --------------------------------------------------
# -- goaccess
# --------------------------------------------------
help_software[goaccess]="Install goaccess latest"
function software_goaccess () {
    if [[ $MACHINE_OS == "linux" && $MACHINE_OS_FLAVOUR == "debian" ]]; then
        wget -O - https://deb.goaccess.io/gnugpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/goaccess.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/goaccess.gpg arch=$(dpkg --print-architecture)] https://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/goaccess.list
        sudo apt-get update
        sudo apt-get install goaccess
    else
        _error "goaccess not supported on $MACHINE_OS"
    fi
}



# --------------------------------------------------
# -- fpart
# --------------------------------------------------
help_software[fpart]="Install fpart"
function software_fpart () {
	if [[ $MACHINE_OS == "linux" && $MACHINE_OS_FLAVOUR == "debian" ]]; then
		sudo apt-get install fpart bsd-mailx- postfix- --no-install-recommends
	else
		_error "fpart not supported on $MACHINE_OS"
	fi
}

# --------------------------------------------------
# -- gcloud
# --------------------------------------------------
help_software[gcloud]="Install gcloud"
function software_gcloud () {
	if [[ $MACHINE_OS_FLAVOUR == "ubuntu" ]]; then
		_loading "Installing gcloud"
		_loading3 "Adding repo to apt"
		echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
		curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
		sudo apt-get update
		_loading3 "Installing gcloud"
		sudo apt-get install google-cloud-sdk
	else
		_error "gcloud not supported on $MACHINE_OS / $MACHINE_OS_FLAVOUR"
	fi
}

# ====================================================================================================
# -- fzf
# ====================================================================================================
help_software[fzf]="Install fzf"
function software_fzf () {
	if [[ $MACHINE_OS == "mac" ]]; then
		brew install fzf
	elif [[ $MACHINE_OS == "linux" ]]; then
		sudo apt-get install fzf
	fi
}

# ====================================================================================================
# docker-ctop
# ====================================================================================================
help_software[docker-ctop]="Install docker-ctop"
function software_docker-ctop() {
	if [[ $MACHINE_OS == "linux" ]]; then
		sudo apt-get install ca-certificates curl gnupg lsb-release
		curl -fsSL https://azlux.fr/repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/azlux-archive-keyring.gpg
		echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian \
		stable main" | sudo tee /etc/apt/sources.list.d/azlux.list >/dev/null
		sudo apt-get update
		sudo apt-get install docker-ctop
	else
		_error "docker-ctop not supported on $MACHINE_OS"
	fi
}

# ====================================================================================================
# -- docker - Install Docker CE
# ====================================================================================================
help_software[docker]='Install Docker CE (Ubuntu 22/24)'
function software_docker () {
    # -- Parse options
    local -a opts_help opts_dry_run
    zparseopts -D -E -- h=opts_help -help=opts_help -dry-run=opts_dry_run

    if [[ -n $opts_help ]]; then
        echo "Usage: software docker [--dry-run]"
        echo "  --dry-run   Preview commands without executing them"
        echo ""
        echo "Install Docker CE via the official Docker apt repository."
        echo "Currently supports Ubuntu 22.04 and 24.04."
        return 0
    fi

    # -- Dry run helper
    local dry_run=0
    [[ -n $opts_dry_run ]] && dry_run=1 && _notice "Dry run mode enabled -- no commands will be executed"

    _run_cmd () {
        if [[ $dry_run -eq 1 ]]; then
            _loading3 "[dry-run] $*"
        else
            eval "$@"
        fi
    }

    # -- OS gate
    local ver_major="${MACHINE_OS_VERSION%%.*}"

    if [[ $MACHINE_OS != "linux" ]]; then
        _error "Docker CE install is only supported on Linux (detected: $MACHINE_OS)"
        unset -f _run_cmd
        return 1
    fi

    case "$MACHINE_OS_FLAVOUR" in
        ubuntu)
            if [[ "$ver_major" != "22" && "$ver_major" != "24" ]]; then
                _error "Docker CE install supports Ubuntu 22/24 (detected: $MACHINE_OS_VERSION)"
                unset -f _run_cmd
                return 1
            fi
            ;;
        # -- Future OS support can be added here
        # debian)
        #     ;;
        *)
            _error "Docker CE install not supported on $MACHINE_OS_FLAVOUR"
            unset -f _run_cmd
            return 1
            ;;
    esac

    # -- Check if Docker is already installed
    if (( $+commands[docker] )) && [[ $dry_run -eq 0 ]]; then
        _warning "Docker is already installed ($(docker --version))"
        _warning "To reinstall, first remove with: sudo apt-get remove docker-ce docker-ce-cli containerd.io docker-compose-plugin"
        unset -f _run_cmd
        return 0
    fi

    _loading "Installing Docker CE on $MACHINE_OS_FLAVOUR $MACHINE_OS_VERSION"

    # -- Remove legacy Docker packages
    _loading2 "Removing legacy Docker packages"
    _run_cmd sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # -- Install prerequisites
    _loading2 "Installing prerequisites"
    _run_cmd sudo apt-get update
    _run_cmd sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # -- Add Docker GPG key
    _loading2 "Adding Docker official GPG key"
    _run_cmd sudo install -m 0755 -d /etc/apt/keyrings
    _run_cmd "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
    _run_cmd sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # -- Add Docker apt repository
    _loading2 "Adding Docker apt repository"
    _run_cmd "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"

    # -- Install Docker CE
    _loading2 "Installing Docker CE packages"
    _run_cmd sudo apt-get update
    _run_cmd sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # -- Verify installation
    if [[ $dry_run -eq 0 ]]; then
        if (( $+commands[docker] )); then
            _success "Docker CE installed successfully: $(docker --version)"
        else
            _error "Docker CE installation may have failed -- docker command not found"
            unset -f _run_cmd
            return 1
        fi
    else
        _success "[dry-run] Docker CE install steps completed"
    fi

    unset -f _run_cmd
}

# ====================================================================================================
# -- fail2ban - Install and configure fail2ban with SSH brute-force protection
# ====================================================================================================
help_software[fail2ban]='Install and configure fail2ban with SSH brute-force protection'

# --------------------------------------------------
# -- _software_fail2ban_usage () - Print usage
# --------------------------------------------------
function _software_fail2ban_usage () {
    echo "Usage: software fail2ban [OPTIONS]"
    echo ""
    echo "Install and configure fail2ban with SSH jail protection (Debian/Ubuntu)."
    echo ""
    echo "Options:"
    echo "  -h, --help      This message"
    echo "  -f, --force     Overwrite existing /etc/fail2ban/jail.local"
    echo ""
    echo "What this does:"
    echo "  1. Install fail2ban via apt"
    echo "  2. Write hardened [sshd] jail config to /etc/fail2ban/jail.local"
    echo "  3. Enable and start the fail2ban service"
    echo "  4. Verify service is running"
    echo "  5. Run 'hardcheck fail2ban' to confirm audit passes"
    echo ""
    return 0
}

# --------------------------------------------------
# -- software_fail2ban () - Install and configure
# --------------------------------------------------
function software_fail2ban () {
    local -a opts_help opts_force
    zparseopts -D -E -- h=opts_help -help=opts_help f=opts_force -force=opts_force

    # -- Help --
    if [[ -n $opts_help ]]; then
        _software_fail2ban_usage
        return 0
    fi

    # -- OS guard: Debian/Ubuntu only --
    if [[ "$MACHINE_OS" != "linux" || ( "$MACHINE_OS_FLAVOUR" != "ubuntu" && "$MACHINE_OS_FLAVOUR" != "debian" ) ]]; then
        _error "fail2ban installer requires apt (Debian/Ubuntu) — detected: $MACHINE_OS / $MACHINE_OS_FLAVOUR"
        return 1
    fi

    _loading "Installing and configuring fail2ban for SSH protection"

    # -- Check if already installed --
    if dpkg-query -l fail2ban &>/dev/null; then
        _success "fail2ban is already installed"
    else
        _loading2 "Installing fail2ban package"
        sudo apt-get update -qq && sudo apt-get install -y fail2ban
        if ! dpkg-query -l fail2ban &>/dev/null; then
            _error "fail2ban installation failed"
            return 1
        fi
        _success "fail2ban installed successfully"
    fi

    # -- Configure SSH jail --
    local jail_local="/etc/fail2ban/jail.local"
    if [[ -f "$jail_local" && -z $opts_force ]]; then
        _warning "$jail_local already exists — skipping config (use --force to overwrite)"
    else
        if [[ -f "$jail_local" && -n $opts_force ]]; then
            local bak="${jail_local}.bak-$(date +%s)"
            _loading3 "Backing up existing config to $bak"
            sudo cp "$jail_local" "$bak"
        fi

        _loading2 "Writing SSH jail config to $jail_local"
        sudo tee "$jail_local" > /dev/null <<'EOF'
# fail2ban jail.local — managed by zshbop software fail2ban
[DEFAULT]
# Ban IP for 1 hour
bantime = 3600
# 10 minute window for finding failures
findtime = 600
# Ban after 3 failures
maxretry = 3

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
EOF
        _success "SSH jail configured (bantime=3600, maxretry=3)"
    fi

    # -- Enable and start service --
    _loading2 "Enabling and starting fail2ban service"
    sudo systemctl enable fail2ban --now

    # -- Verify service is active --
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        _success "fail2ban service is running"
    else
        _warning "fail2ban service is NOT running — check 'systemctl status fail2ban'"
    fi

    # -- Auto-verify with hardcheck --
    if typeset -f hardcheck &>/dev/null; then
        _loading2 "Verifying with hardcheck fail2ban"
        hardcheck fail2ban
    else
        _notice "hardcheck not available — skip auto-verification (run 'hardcheck fail2ban' manually to audit)"
    fi

    echo ""
    _success "fail2ban setup complete — SSH is now protected against brute-force attacks"
    echo "  Check status:  sudo fail2ban-client status sshd"
    echo "  View bans:     sudo grep 'Ban' /var/log/fail2ban.log"
}