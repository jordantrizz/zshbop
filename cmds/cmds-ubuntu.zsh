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
        echo "Usage: ubuntu-swap-create <size>"        
        echo "Creates a swap file of size 4GB at /swapfile if not size is provided."
        echo
        echo "Current memory size: $MEM_SIZE"
    }
    SWAP_SIZE=4G    
    MEM_SIZE=$(free -h | grep Mem | awk '{print $2}')
    # Check if the user provided a size argument
    if [[ $# -gt 1 ]]; then
        _ubuntu-swap-create-usage
        return 1
    fi

    # Check if swap file already exists
    if [[ -f /swapfile ]]; then        
        _loading "Swap file already exists. Checking size..."
                # Check if the swap file is larger thatn SWAP_SIZE
        CURRENT_SWAP_SIZE=$(sudo du -h /swapfile | awk '{print $1}')
        # Remove the G from the size
        CURRENT_SWAP_SIZE=${CURRENT_SWAP_SIZE%G}
        SWAP_SIZE=${SWAP_SIZE%G}
        _loading2 "Current swap file size: $CURRENT_SWAP_SIZE"        
        if [[ $CURRENT_SWAP_SIZE -gt $SWAP_SIZE ]]; then
            echo "Swap file is larger than $SWAP_SIZE. Please remove it first."
            return 1
        fi
        # Check if the swap file is smaller than SWAP_SIZE
        if [[ $CURRENT_SWAP_SIZE -lt $SWAP_SIZE ]]; then
            echo "Swap file is smaller than $SWAP_SIZE. Please remove it first."
            return 1
        fi
    fi
    

    # Check if the user provided a size argument
    if [[ $# -eq 1 ]]; then
        # Ensure there is a G on the end
        if [[ $1 != *G ]]; then
            echo "Size must be in GB (e.g., 4G)."
            _ubuntu-swap-create-usage
            return 1
        fi
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
    sudo fallocate -l $SWAP_SIZE /swapfile
    
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