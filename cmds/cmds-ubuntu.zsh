# --
# Ubuntu commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[ubuntu]='Ubuntu OS related commands'

# - Init help array
typeset -gA help_ubuntu

# =====================================
# -- netselect-fastest
# =====================================
help_ubuntu[netselect-fastest]='Find the fastest Ubuntu mirror'
alias netselect-fastest='sudo netselect -v -s10 -t20 `wget -q -O- https://launchpad.net/ubuntu/+archivemirrors | grep -P -B8 "statusUP|statusSIX" | grep -o -P "(f|ht)tp://[^\"]*"`'

# =====================================
# -- ubuntu-swap-create
# =====================================
help_ubuntu[ubuntu-swap-create]='Create a swap file'
function ubuntu-swap-create () {
    _ubuntu-swap-create-usage () {
        echo "Usage: ubuntu-swap-create <size-in-GB-wthout-G>"        
        echo "Creates a swap file of size 4G at /swapfile if not size is provided."
        echo
        echo "Current memory size: $MEM_SIZE"
    }
    SWAP_SIZE=4
    MEM_SIZE=$(free -h | grep Mem | awk '{print $2}')
    # Remove the Gi from the size
    MEM_SIZE=${MEM_SIZE%Gi}
    # Check if the user provided a size argument
    if [[ $# -gt 1 ]]; then
        _ubuntu-swap-create-usage
        return 1
    fi   

    # Check if the user provided a size argument
    if [[ $# -eq 1 ]]; then            
        # Check if the size is a valid number
        if ! [[ $1 =~ ^[0-9]+$ ]]; then
            echo "Size must be a number."
            _ubuntu-swap-create-usage
            return 1
        fi
        # Check if the size is greater than the current memory size
        if [[ $1 -gt $MEM_SIZE ]]; then
            echo "Size must be less than or equal to the current memory size ($MEM_SIZE)."
            _ubuntu-swap-create-usage
            return 1
        fi
        SWAP_SIZE=$1
    fi

    # Check if swap file already exists
    if [[ -f /swapfile ]]; then        
        _loading "Swap file already exists. Checking size..."
                # Check if the swap file is larger thatn SWAP_SIZE
        CURRENT_SWAP_SIZE=$(sudo du -h /swapfile | awk '{print $1}')
        # Remove the G from the size
        CURRENT_SWAP_SIZE=${CURRENT_SWAP_SIZE%G}
        # Remove decimal point
        CURRENT_SWAP_SIZE=${CURRENT_SWAP_SIZE%.*}        
        _loading2 "Current swap file size: ${CURRENT_SWAP_SIZE}G suggested size: ${SWAP_SIZE}G"        
        if [[ $CURRENT_SWAP_SIZE -gt $SWAP_SIZE ]]; then
            _error "Current Swap file is larger than $SWAP_SIZE, not changing"
            return 1
        elif  [[ $CURRENT_SWAP_SIZE -lt $SWAP_SIZE ]]; then
            _loading3 "Current Swap File: ${CURRENT_SWAP_SIZE}G smaller than ${SWAP_SIZE}G..Resizing"                    
            sudo swapoff /swapfile            
            sudo fallocate -l ${SWAP_SIZE}G /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile                    
            return 1
        else
            _loading3 "Current Swap File: ${CURRENT_SWAP_SIZE}G is the same as ${SWAP_SIZE}G..Not changing"                    
            return 1
        fi
    fi

    _loading "Creating swap file of size $SWAP_SIZE..."
    # Check if the user is root
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Use sudo."
        return 1
    fi
    # Check if the system is Ubuntu
    if [[ ! -f /etc/lsb-release ]]; then
        echo "This script is only for Ubuntu."
        return 1
    fi

    # Create a swap file of size 1GB
    sudo fallocate -l ${SWAP_SIZE}G /swapfile
    
    # Set the correct permissions
    sudo chmod 600 /swapfile
    
    # Set up the swap area
    sudo mkswap /swapfile
    
    # Enable the swap file
    sudo swapon /swapfile
    
    # Add to fstab for automatic mounting on boot
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo "Swap file created and enabled."
}

# =====================================
# -- ubuntu-resolve-dns  
# =====================================
help_ubuntu[ubuntu-resolve-dns]='Manage systemd-resolved DNS settings with options: --update, --show, or no args for usage'
function ubuntu-resolve-dns () {
    
    # Usage function
    _ubuntu-resolve-dns-usage () {
        echo "Usage: ubuntu-resolve-dns [OPTION]"
        echo
        echo "Manage systemd-resolved DNS settings"
        echo
        echo "Options:"
        echo "  --update    Update DNS settings to use Google (8.8.8.8) and Cloudflare (1.1.1.1)"
        echo "  --show      Show current DNS configuration"
        echo "  (no args)   Show this usage and current configuration"
        echo
    }

    # Show current configuration function
    _ubuntu-resolve-dns-show () {
        _loading "Showing current DNS configuration..."

        # Check if systemd-resolved is running
        _loading2 "Checking systemd-resolved status..."
        if systemctl is-active --quiet systemd-resolved; then
            echo "✅ systemd-resolved is running"
        else
            echo "❌ systemd-resolved is not running"
        fi

        echo
        echo "=== Current /etc/systemd/resolved.conf ==="
        if [[ -f /etc/systemd/resolved.conf ]]; then
            cat /etc/systemd/resolved.conf
            # Check for DNS override
            DNS_LINE=$(grep '^DNS=' /etc/systemd/resolved.conf)
            FALLBACK_LINE=$(grep '^FallbackDNS=' /etc/systemd/resolved.conf)
            if [[ -n "$DNS_LINE" || -n "$FALLBACK_LINE" ]]; then
                echo "\n-- DNS override present --"
                [[ -n "$DNS_LINE" ]] && echo "$DNS_LINE"
                [[ -n "$FALLBACK_LINE" ]] && echo "$FALLBACK_LINE"
            fi
        else
            echo "File not found"
        fi

        echo
        echo "=== Current DNS Status (resolvectl status) ==="
        if command -v resolvectl >/dev/null 2>&1; then
            resolvectl status 2>/dev/null || echo "Unable to get resolvectl status"
            # Grab Global DNS
            GLOBAL_DNS=$(resolvectl dns | grep '^Global:' | awk '{print $2}')
            if [[ -n "$GLOBAL_DNS" ]]; then
                echo "\nGlobal DNS: $GLOBAL_DNS"
                # Warn if not Google/Cloudflare
                if [[ "$GLOBAL_DNS" != "8.8.8.8" && "$GLOBAL_DNS" != "1.1.1.1" && "$GLOBAL_DNS" != "8.8.4.4" && "$GLOBAL_DNS" != "1.0.0.1" ]]; then
                    _warning "Global DNS is not Google/Cloudflare: $GLOBAL_DNS"
                fi
            fi
        else
            echo "resolvectl command not available"
        fi

        echo
        echo "=== Current /etc/resolv.conf ==="
        if [[ -f /etc/resolv.conf ]]; then
            cat /etc/resolv.conf
        else
            echo "File not found"
        fi
    }

    # Update DNS settings function
    _ubuntu-resolve-dns-update () {
        _loading "Updating systemd-resolved DNS settings to Google/Cloudflare DNS..."
        
        # Check if systemd-resolved is running, if not fail
        _loading2 "Checking if systemd-resolved is running..."
        if ! systemctl is-active --quiet systemd-resolved; then
            _error "systemd-resolved is not running"
            return 1
        else
            _loading2 "systemd-resolved is running"
        fi

        # -- Check if we're running as root
        if ! _checkroot; then
            _error "This command must be run as root."
            return 1
        fi    

        # -- Backup current configuration
        _loading2 "Backing up current /etc/systemd/resolved.conf..."
        sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

        # -- Edit /etc/systemd/resolved.conf
        _loading2 "Editing /etc/systemd/resolved.conf to set DNS servers..."
        cat << 'EOF' | sudo tee /etc/systemd/resolved.conf > /dev/null
[Resolve]
DNS=8.8.8.8 1.1.1.1
FallbackDNS=8.8.4.4 1.0.0.1
Domains=~.
DNSSEC=yes
DNSOverTLS=yes
Cache=yes
EOF

        # -- Restart systemd-resolved
        _loading "Restarting systemd-resolved..."
        sudo systemctl restart systemd-resolved

        _loading2 "systemd-resolved restarted. Checking status..."
        # -- Check status
        resolvectl status
    }

    # Parse arguments
    case "${1:-}" in
        --update)
            _ubuntu-resolve-dns-update
            ;;
        --show)
            _ubuntu-resolve-dns-show
            ;;
        --help|-h|help)
            _ubuntu-resolve-dns-usage
            ;;
        "")
            # No arguments - show usage and current config
            _ubuntu-resolve-dns-usage
            echo
            _ubuntu-resolve-dns-show
            ;;
        *)
            echo "Unknown option: $1"
            echo
            _ubuntu-resolve-dns-usage
            return 1
            ;;
    esac
}

# ==================================================
# -- ubuntu-check-restart
# ==================================================
help_ubuntu[ubuntu-check-restart]='Check if a system restart is required'
function ubuntu-check-restart () {
    _loading "Checking if a system restart is required..."
    # Check if /var/run/reboot-required exists
    if [[ -f /var/run/reboot-required ]]; then
        _loading2 "A system restart is required."
        echo "Please restart your system."
        return 0
    else
        _loading2 "No system restart is required."
        return 1
    fi
}