# --
# Proxmox helper commands
# --
_debugf " -- Loading ${(%):-%N}"

#####################################################################
#####################################################################

# -------------------------------------------------------------------
# -- proxmox helper
# -------------------------------------------------------------------
alias pmox='proxmox'
function proxmox () {
        if [[ $1 == "help" ]] || [[ -z $1 ]]; then
            _proxmox_help
        elif [[ -n $1 ]]; then
	        _debugf "-- Running pmox $1"
            proxmox_init $@
        fi
}

# -------------------------------------------------------------------
# -- proxmox_init
# -------------------------------------------------------------------
function proxmox_init () {
    # -- debug
    _debug_all
    ALL_ARGS="$@"
    zparseopts -D -E d=DEBUG dr=DRYRUN name:=NAME memory:=MEM network:=NET storage:=STORAGE disksize:=DISKSIZE os:=OS_RELEASE dhcpnet:=DHCP_NET tempdir:=TEMP_DIR sshkey:=SSH_KEY vmid:=VM_ID ip:=IP bridge:=BRIDGE cloneid:=CLONE_ID mac:=MAC gw:=GW cpu:=CPU
    [[ $DEBUG ]] && DEBUGF="1" || DEBUGF="0"

    _loading "Starting Proxmox Helper"

    # -- Set defaults
    [[ -z $CPU ]] && CPU="1" || CPU=$CPU[2]
    [[ -z $MEM ]] && MEM="2" || MEM=$MEM[2]
    [[ -z $NET ]] && NET="vmbr0" || NET=$NET[2]
    [[ -z $STORAGE ]] && STORAGE="local" || STORAGE=$STORAGE[2]
    [[ -z $DISKSIZE ]] && DISKSIZE="20" || DISKSIZE=$DISKSIZE[2]
    [[ -z $OS_RELEASE ]] && OS_RELEASE="noble" || OS_RELEASE=$OS_RELEASE[2]
    [[ -z $DHCP_NET ]] || DHCP_NET=$DHCP_NET[2]
    [[ -z $TEMP_DIR ]] && TEMP_DIR="/tmp" || TEMP_DIR=$TEMP_DIR[2]
    [[ -z $SSH_KEY ]] && SSH_KEY="$HOME/.ssh/id_rsa.pub" || SSH_KEY=$SSH_KEY[2]
    [[ -z $NAME ]] || NAME=$NAME[2]
    [[ -z $IP ]] && IP="dhcp" || IP=$IP[2]
    [[ -z $BRIDGE ]] && BRIDGE="vmbr0" || BRIDGE=$BRIDGE[2]
    [[ -z $CLONE_ID ]] && CLONE_ID="9000" || CLONE_ID=$CLONE_ID[2]
    [[ -z $MAC ]] && MAC="" || MAC=$MAC[2]
    [[ -z $GW ]] && GW="" || GW=$GW[2]
    [[ -z $VM_ID ]] && VM_ID="" || VM_ID=$VM_ID[2]

    # -- Convert GB to MB for MEM
    MEM=$(_proxmox_mem_gb2mb $MEM)

    # -- Convert DISKSIZE to MB
    DISKSIZE=$(_proxmox_disk_gb2mb $DISKSIZE)

    _debugf "ALL_ARGS: $ALL_ARGS"
    _debugf "DEBUG: $DEBUG"
    _debugf "DRYRUN: $DRYRUN"
    _debugf "HELP: $HELP"
    _debugf "NAME: $NAME"
    _debugf "CPU: $CPU"
    _debugf "MEM: $MEM"
    _debugf "NET: $NET"
    _debugf "STORAGE: $STORAGE"
    _debugf "DISKSIZE: $DISKSIZE"
    _debugf "OS_RELEASE: $OS_RELEASE"
    _debugf "DHCP_NET: $DHCP_NET"
    _debugf "TEMP_DIR: $TEMP_DIR"
    _debugf "SSH_KEY: $SSH_KEY"
    _debugf "VM_ID: $VM_ID"
    _debugf "IP: $IP"
    _debugf "BRIDGE: $BRIDGE"
    _debugf "CLONE_ID: $CLONE_ID"
    _debugf "MAC: $MAC"
    _debugf "GW: $GW"

    REQUIRED_PKG=('curl' 'libguestfs-tools')
    _debugf $REQUIRED_PKG
	_require_pkg $REQUIRED_PKG

    # -- Check command
    if [[ $1 == "createvm" ]]; then
        # -- Check required options
        if [[ -z $NAME ]]; then
            _proxmox_help
            _error "Name is required"
            return 1
        fi
        _debugf "Creating VM"
        _loading "Creating Proxmox VM"
        echo ""

        # -- Get VM ID
        _proxmox_getid
        echo ""

        _proxmox_check || return 1
        echo ""

        _proxmox_createvm
        echo ""
    # -- Create template
    elif [[ $1 == "createtemp" ]]; then
        _debugf "Creating template"
        _proxmox_check || return 1
        _proxmox_createtemp
    # -- Clone template
    elif [[ $1 == "clonetemp" ]]; then
        _debugf "Cloning template"
        _proxmox_check || return 1
        _proxmox_clonetemp
    # -- Image existing vm
    elif [[ $1 == "imagevm" ]]; then
        _debugf "Imaging VM"
        _proxmox_check || return 1
        _loading "Imaging Proxmox VM with ID $VM_ID and OS $OS_RELEASE"
        _proxmox_imagevm "$@"
    # -- Setup vendor cloudinit.yaml
    elif [[ $1 == "vendorci" ]]; then
        _debugf "Setting up vendor cloudinit.yaml"
        _proxmox_vendorci
    elif [[ $1 == "info" ]]; then
        _debugf "Getting info"
        _proxmox_check || return 1
        _proxmox_info
    elif [[ $1 == help ]]; then
        _debugf "Getting help"
        _proxmox_help
    else
        _debugf "Unknown command $1"
        _proxmox_help
        _error "Unknown command $1"
    fi

}

# -------------------------------------------------------------------
# -- proxmox_help
# -------------------------------------------------------------------
function _proxmox_help () {
	_loading "Proxmox Helper"
    echo \
"
Usage: pmox <command> <options>

Main Commands:
  createvm      - Create VM
  createtemp    - Create template
  clonetemp     - Clone template

Other Commands:
  imagevm <id> <os-release>       - Apply image to VM
  vendorci                        - Setup vendor cloudinit.yaml
  info                            - Info about Proxmox instance
  help                            - This help

Global Options:
  -d            - Debug mode
  -dr           - Dry run

Command Options:

  createvm <options>
  ------------------
    Required:
        -name <name>              Name of the VM

    Optional:
        -cpu <count>              Number of CPU cores (Default: 1)
        -memory <memory>          Memory of VM in GB (Default: 2) Ex. 0.5 = 512MB 1 = 1GB 2 = 2GB etc.
        -network <network>        Network bridge to use (Default: vmbr0)
        -storage <storage>        Storage location (Autodetect)
        -disksize <disksize>      Disk size in GB (Default: 20)
        -os <os>                  bionic,focal,jammy, noble (Default: jammy)
        -dhcpnet [dhcpnet]        If you have a local network with dhcp, the bridge it's on.
        -tempdir [tempdir]        Setup temporary directory for download for cloudimage, optional.
        -sshkey [sshkey]          SSH key to add to VM, optional. (Default: ~/.ssh/id_rsa.pub)
        -vmid [vmid]              VM ID to use, (Default: random)
        -cloneid [vmid]           VM ID to clone, (Default: 9000)
        -mac [mac]                MAC address to use, optional.
        -ip [ip]                  IP address to use, optional. (Default: dhcp)
        -gw [gw]                  Gateway to use, optional.
        -bridge [bridge]          Network bridge to use, optional. (Default: vmbr0)


	Example: createvm -name server -memory 2 -network vmbr0 -storage local -disksize 80 -os focal

  createtemp <options>
  --------------------
    -os <os>                  bionic,focal,jammy,noble default jammy
    -bridge <bridge>          Network bridge to use, default vmbr0
    -storage <storage>        Storage location, default local-lvm
    -vmid <vmid>              VM ID to use, default 9000

  clonetemp <options>
  -------------------
    -name <name>              Name of the VM
    -vmid [vmid]              VM ID to use (Default: 9000)
    -ip [ip]                  IP address to use (Default: dhcp)

  OS:
    Ubuntu 24.04 LTS = noble
    Ubuntu 22.04 LTS = jammy
    Ubuntu 20.04.4 LTS = focal
    Ubuntu 18.04.6 LTS = bionic
    "
}

# ===================================================================
# -- _proxmox_check
# -- check if proxmox is installed and other checks
# ===================================================================
function _proxmox_check () {
    INSTALL_PKG=()
    # -- check for pvesh
    _loading2 "Pre-flight checks"
    if [[ $DRYRUN == "1" ]]; then
        _loading3 "Doing a dryrun"
	else
        # Define associative array with commands and error messages
        typeset -A PROXMOX_REQUIRED_COMMANDS
        PROXMOX_REQUIRED_COMMANDS=(
            pvesh "pvesh"
            lshw "lshw"
            virt-customize "libguestfs-tools"
            jq "jq"
        )

        # Iterate over the associative array
        for cmd in "${(@k)PROXMOX_REQUIRED_COMMANDS}"; do
            if command -v $cmd &>/dev/null; then
                _success "$cmd is installed"
            else
                # Add to array
                INSTALL_PKG+=("${PROXMOX_REQUIRED_COMMANDS[$cmd]}")
            fi
        done
        # Check if INSTALL_PKG is empty
        if [[ -n $INSTALL_PKG ]]; then
            _loading3 "Installing required packages $INSTALL_PKG"
            apt-get install -y --no-install-recommends $INSTALL_PKG
        fi
    fi

    # -- Get Proxmox node name
    PROXMOX_NODE_NAME=$(pvesh ls nodes | awk '{ print $2}')
}

# ===================================================================
# -- _proxmox_getid
# -- Get Proxmox VM ID
# ===================================================================
function _proxmox_getid () {
    # -- Get Proxmox VM ID
    _loading2 "Generating Proxmox VM ID"
    if [[ -z $VM_ID ]]; then
        _loading3 "No VM ID set, getting random VM ID"
        VM_ID=$(pvesh get /cluster/nextid);
        _loading3 "VM ID set to $VM_ID"
    else
        _loading3 "VM ID set to $VM_ID"
    fi
}

# ===================================================================
# -- _proxmox_mem_gb2mb
# -- Convert GB to MB
# ===================================================================
function _proxmox_mem_gb2mb () {
    local GB
    GB=$1
    echo $((GB * 1024))
}

# ===================================================================
# -- _proxmox_disk_gb2mb
# -- Convert GB to MB
# ===================================================================
function _proxmox_disk_gb2mb () {
    local GB
    GB=$1
    echo $((GB * 1024 ))
}

# ===================================================================
# -- _proxmox_get_storage
# -- Get Proxmox storage
# ===================================================================
function _proxmox_get_storage () {
    # -- Get Proxmox storage
    local PROXMOX_STORAGE_API
    PROXMOX_STORAGE_API=$(pvesh get /storage --output-format json)
    _debugf "PROXMOX_STORAGE_API: $PROXMOX_STORAGE_API"
    PROXMOX_STORAGE=($(echo "$PROXMOX_STORAGE_API" | jq -r '.[] | select(.content | contains("images")) | .storage'))
    _debugf "PROXMOX_STORAGE: $PROXMOX_STORAGE"

    # Count number of storage items, all on same line with a space.
    PROXMOX_STORAGE_COUNT=$(echo "$PROXMOX_STORAGE" | wc -w)
    _debugf "PROXMOX_STORAGE_COUNT: $PROXMOX_STORAGE_COUNT"
    if [[ $PROXMOX_STORAGE_COUNT -gt 1 ]]; then
        _debugf "Multiple storage locations found, using first one"
        PROXMOX_STORAGE=$(echo "$PROXMOX_STORAGE" | awk '{ print $1 }')
    fi

    if [[ -z $PROXMOX_STORAGE ]]; then
        _error "No storage set"
        return 1
    else
        echo "$PROXMOX_STORAGE"
    fi
}

# -------------------------------------------------------------------
# -- _proxmox_download_cloudimage $OS_RELEASE
# -------------------------------------------------------------------
function _proxmox_download_cloudimage () {
    local OS_RELEASE
    OS_RELEASE=$1
    # -- Check if $OS_RELEASE is valid
    _loading2 "Checking if $OS_RELEASE is a valid OS"
    AVAIL_OS=("focal" "bionic" "jammy" "noble")
    _if_marray "$OS_RELEASE" AVAIL_OS
    if [[ $MARRAY_VALID == "1" ]]; then
        _error "Couldn't get Ubuntu Image for $OS_RELEASE"
        return 1
    else
        _loading3 "OS: $OS_RELEASE is valid"
    fi
    echo ""

    # -- Generate OS download URL and path
    IMAGE_FILE="${OS_RELEASE}-server-cloudimg-amd64.img"
    IMAGE_URL="https://cloud-images.ubuntu.com/${OS_RELEASE}/current/${IMAGE_FILE}"
    IMAGE_FILE_PATH="${TEMP_DIR}/${IMAGE_FILE}"
    _loading2 "Fetching $OS_RELEASE Image from $IMAGE_URL into $IMAGE_FILE_PATH"

    # -- Check if $IMAGE_FILE exists
    _loading4 "Checking if $IMAGE_FILE exists in $TEMP_DIR"
    if [[ -f ${IMAGE_FILE_PATH} ]]; then
        _loading4 "Found $IMAGE_FILE_PATH"

        # -- Check if $IMAGE_FILE has a valid MD5SUM hash
        _loading4 "Checking MD5"
        IMAGE_URL_MD5=$(curl -s https://cloud-images.ubuntu.com/$OS_RELEASE/current/MD5SUMS | grep "$OS_RELEASE-server-cloudimg-amd64.img" | awk {' print $1 '})
        IMAGE_FILE_MD5=$(md5sum $IMAGE_FILE_PATH | awk {'print $1'})
        _loading4 "\$OS_URL_MD5: $IMAGE_URL_MD5 \$OS_FILE_MD5: $IMAGE_FILE_MD5"

        # -- Check if $IMAGE_FILE_MD5 matches $IMAGE_URL_MD5
        if [[ $IMAGE_URL_MD5 == $IMAGE_FILE_MD5 ]]; then
            _loading4 "Local file $IMAGE_FILE_PATH matches remote MD5, continuing build"
        else
            _error "Local file $IMAGE_FILE_PATH MD5 does not match remote MD5."
            _loading4 "Downloading $IMAGE_URL into $TEMP_DIR"
            _debugf "curl --output $IMAGE_FILE_PATH $IMAGE_URL"
            curl --output $IMAGE_FILE_PATH $IMAGE_URL
        fi
    else
        # -- Download $IMAGE_URL into $IMAGE_FILE_PATH if it doesn't exist
        _debugf "curl --output $IMAGE_FILE_PATH $IMAGE_URL"
        curl --output $IMAGE_FILE_PATH $IMAGE_URL
    fi
    echo ""
}

# -------------------------------------------------------------------
# -- _proxmox_generate_ip $ipconfig
# -------------------------------------------------------------------
function _proxmox_generate_ip () {
    IPCONFIG=$1
    # Checking if IP and GW is set
    if [[ -n $IP ]] && [[ -n $GW ]]; then
        _loading3 "IP and GW set"
        # -- Make sure IP has CIDR
        _loading3 "Checking if IP has CIDR"
        if [[ $IP != *"/"* ]]; then
            _loading3 "Adding CIDR to IP"
            IP="${IP}/24"
        fi
        _loading3 "Setting IP to ${IP} and GW to ${GW} on ${IPCONFIG}"
        _debugf "qm set ${VM_ID} --${IPCONFIG} ip=${IP},gw=${GW}"
        qm set ${VM_ID} --${IPCONFIG} ip=${IP},gw=${GW}
    else
        _loading3 "No IP or GW set, skipping"
    fi
}

# -------------------------------------------------------------------
# -- _proxmox_imagevm
# -------------------------------------------------------------------
function _proxmox_imagevm () {
    local TEMP_DIR IMAGE_FILE BUILD_IMAGE STORAGE SKIP_SCSI0
    TEMP_DIR="/tmp"
    IMAGE_FILE="${OS_RELEASE}-server-cloudimg-amd64.img"

    zparseopts -D -E skip-scsi0=SKIP_SCSI0
    [[ $SKIP_SCSI0 ]] && SKIP_SCSI0="1" || SKIP_SCSI0="0"

    STORAGE=$(_proxmox_get_storage)
    if [[ $? -ne 0 ]]; then
        _error "Failed to get storage - $STORAGE"
        return 1
    fi

    # -- Check if $VM_ID is set
    _loading2 "Checking if VMID is set and creater than 0"
    if [[ -z $VM_ID ]]; then
        _error "VMID is not set"
        return 1
    else
        _loading3 "VMID is set to $VM_ID"
    fi

    # -- Checkif $VMID exists
    _loading2 "Checking if VMID $VM_ID exists"
    QM_LIST=$(qm list | awk '{print $1}' | grep -v 'VMID')
    _debugf "QM_LIST: $QM_LIST VM_ID: $VM_ID"
    if echo "$QM_LIST" | grep -q "$VM_ID"; then
        _loading3 "VMID $VM_ID exists."
    else
        _error "VMID $VM_ID does not exist."
        return 1
    fi

    # -- Confirm VM is shutdown
    _loading2 "Checking if VMID $VM_ID is shutdown"
    if qm status $VM_ID | grep -q "status: stopped"; then
        _loading3 "VMID $VM_ID is stopped"
    else
        _error "VMID $VM_ID is not stopped"
        return 1
    fi

    # -- Check if there are unused disks
    _loading2 "Checking if there are unused disks"
    if qm config $VM_ID | grep -q 'unused'; then
        _error "Unused disks found"
        return 1
    else
        _loading3 "No unused disks found"
    fi

    # -- Check if scsi0 disk exists
    _loading2 "-- Checking if scsi0 disk exists"
    if [[ $SKIP_SCSI0 == "0" ]]; then
        if qm config $VM_ID | grep -q 'scsi0:'; then
            _loading3 "scsi0 disk exists"
        else
            _error "scsi0 disk does not exist, can't re-image VM if no scsi0 disk exists"
            return 1
        fi
    else
        _loading3 "Skipping scsi0 disk check"
    fi

    # -- Download cloudimage
    _proxmox_download_cloudimage $OS_RELEASE
    [[ $? -ne 0 ]] && { _error "Failed to download cloudimage"; return 1; }

    # -- Create a copy of new image
    _loading2 "Create a copy of new image"
    cp ${TEMP_DIR}/${IMAGE_FILE} ${TEMP_DIR}/${IMAGE_FILE}.build
    BUILD_IMAGE="${TEMP_DIR}/${IMAGE_FILE}.build"

    # -- Insert guest tools into image
    _loading2 "-- Inserting guest tools into image"
    ( set -x; virt-customize -a ${BUILD_IMAGE} --install qemu-guest-agent )
    [[ $? -ne 0 ]] && { _error "Failed to insert guest tools into image";return 1; }

    # -- Get scsi0 disk size
    _loading2 "-- Getting scsi0 disk size"
    # scsi0: local:9000/base-9000-disk-0.raw/100/vm-100-disk-0.qcow2,size=99532M
    if [[ $SKIP_SCSI0 == "0" ]]; then
        DISKSIZE=$(qm config $VM_ID | grep 'scsi0:' | awk '{ print $2 }' | awk -F',' '{ print $2 }' | awk -F'=' '{ print $2 }' | awk -F'M' '{ print $1 }')
        _loading3 "scsi0 disk size is $DISKSIZE"
    else
        _loading3 "Skipping scsi0 disk size check, using default 20000M"
        DISKSIZE="20"
    fi

    # -- Confirm deletion of scsi0 disk
    _loading2 "-- Confirm deletion of scsi0 disk"
    read "CONFIRM?Are you sure you want to delete scsi0 disk? [y/N] "
    if [[ $CONFIRM == "y" ]]; then
        _loading3 "Deleting scsi0 disk"
        ( set -x; qm set ${VM_ID} --delete scsi0 )
        [[ $? -ne 0 ]] && { _error "Failed to delete scsi0 disk";return 1; }
    else
        _loading3 "Not deleting scsi0 disk"
    fi

    # -- Remove scsi0 disk
    _loading2 "-- Removing scsi0 disk"
    ( set -x; qm set ${VM_ID} --delete scsi0 )
    [[ $? -ne 0 ]] && { _error "Failed to remove scsi0 disk";return 1; }

    # -- Import disk into VM
    _loading "-- Importing disk into VM: $VM_ID"
    ( set -x; qm importdisk ${VM_ID} ${BUILD_IMAGE} ${PROXMOX_STORAGE} )
    [[ $? -ne 0 ]] && { _error "Failed to import disk into VM";return 1; }

    # -- Assume unused0
    _loading2 "-- Setting VM storage options"
    VM_STORAGE=$(qm config $VM_ID | grep 'unused0' | awk '{ print $2 }')
    ( set -x;qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 "${VM_STORAGE},size=${DISKSIZE}M")
    [[ $? -ne 0 ]] && { _error "Failed to set VM storage options";return 1; }

    # -- Resize disk
    _loading2 "-- Resizing VM_ID:$VM_ID disk to ${DISKSIZE}M"
    ( set -x; qm resize ${VM_ID} scsi0 ${DISKSIZE}M )
    [[ $? -ne 0 ]] && { _error "Failed to resize VM disk";return 1; }
}

# -------------------------------------------------------------------
# -- _proxmox_createvm
# -------------------------------------------------------------------
function _proxmox_createvm () {
    local STORAGE

    # Check if memory is set and a number
    _loading2 "Checking if memory is set and a number"
    if [[ ! $MEM =~ ^[0-9]+$ ]]; then
        _error "Memory is not a number"
        return 1
    else
        _loading3 "Memory is set to $MEM"
    fi
    echo

    # -- Check if storage exists
    STORAGE="$(_proxmox_get_storage)"
    if [[ $? -ne 0 ]]; then
        _error "Failed to get storage - $STORAGE"
        return 1
    fi
    _debugf "STORAGE: $STORAGE"

    # -- Check if $VM_ID is set
    _loading2 "Checking if VMID is set and creater than 0"
    if [[ -z $VM_ID ]]; then
        _error "VMID is not set"
        return 1
    elif [[ $VM_ID -lt 1 ]]; then
        _error "VMID is less than 1"
        return 1
    else
        _loading3 "VMID is set to $VM_ID"
    fi

    # -- Check if VM_ID is taken
    _loading3 "Checking if VMID $VM_ID is taken"
    QM_LIST=$(qm list | awk '{print $1}')
    if echo "$QM_LIST" | grep -q "$VM_ID"; then
        _error "VMID $VM_ID is taken."
        return 1
    else
        _loading3 "VMID $VM_ID is available."
    fi
    echo

    # -- Download cloudimage
    _proxmox_download_cloudimage $OS_RELEASE
    [[ $? -ne 0 ]] && { _error "Failed to download cloudimage"; return 1; }

    # -- Run QM Command
    _loading2 "Creating VM with ID:$VM_ID"
    _loading3 "NAME: $NAME MEM: $MEM DISKSIZE: $DISKSIZE NET: $NET OS_RELEASE: $OS_RELEASE"

    # -- Secondary check to see if any variables are empty
    [[ -z $NAME ]] && { _error "Name is missing";return 1; }
    [[ -z $MEM ]] && { _error "Memory is missing";return 1; }
    [[ -z $DISKSIZE ]] && { _error "Disksize is missing";return 1; }
    [[ -z $NET ]] && { _error "Network is missing";return 1; }
    [[ -z $OS_RELEASE ]] && { _error "OS Release is missing";return 1; }

    (set -x;qm create $VM_ID --name $NAME \
    --cores ${CPU} --sockets 1 \
    --memory $MEM \
    --bootdisk scsi0 \
    --scsihw virtio-scsi-pci \
    --ide2 media=cdrom,file=none \
    --ide0 ${STORAGE}:cloudinit,size=4M \
    --boot cdn \
    --ostype l26 \
    --onboot 1 \
    --cpu host \
    --agent enabled=1,fstrim_cloned_disks=1 \
    --cicustom "vendor=local:snippets/vendor.yaml"
    )
    [[ $? -ne 0 ]] && { _error "Failed to create VM";return 1; }

    _loading2 "Creating net0 interface"
    (set -x;qm set ${VM_ID} --net0 virtio,bridge=${BRIDGE},firewall=1)
    [[ $? -ne 0 ]] && { _error "Failed to create net0 interface";return 1; }

    _loading2 "Setting IP and GW on ipconfig0"
    _proxmox_generate_ip ipconfig0

    _loading2 "Setting MAC address for net0 interface"
    if [[ -n $MAC ]]; then
        _loading3 "Setting MAC address to ${MAC}"
        (set -x; qm set ${VM_ID} --net0 virtio,macaddr=${MAC},bridge=${BRIDGE},firewall=1)
    else
        _loading3 "No MAC address set, setting to random"
    fi

    # -- Enable internal nic with DHCP
    _loading2 "Checking if DHCP network is set"
    if [[ -n $DHCP_NET ]]; then
        _loading3 "Creating net1 with DHCP"
        ( set -x; qm set ${VM_ID} --net1 virtio,bridge=${DHCP_NET},firewall=1)
        ( set -x; qm set ${VM_ID} --ipconfig1 ip=dhcp )
    else
        _loading3 "No DHCP network set, skipping"
    fi

    # -- Download cloudimage
    _proxmox_download_cloudimage $OS_RELEASE
    [[ $? -ne 0 ]] && { _error "Failed to download cloudimage"; return 1; }

    _loading2 "Create a copy of new image"
    cp ${TEMP_DIR}/${IMAGE_FILE} ${TEMP_DIR}/${IMAGE_FILE}.build
    BUILD_IMAGE="${TEMP_DIR}/${IMAGE_FILE}.build"

    _loading2 "-- Inserting guest tools into image"
    ( set -x; virt-customize -a ${BUILD_IMAGE} --install qemu-guest-agent )
    [[ $? -ne 0 ]] && { _error "Failed to insert guest tools into image";return 1; }

    _loading "-- Importing disk into VM: $VM_ID"
    ( set -x; qm importdisk ${VM_ID} ${BUILD_IMAGE} ${STORAGE} )
    [[ $? -ne 0 ]] && { _error "Failed to import disk into VM";return 1; }

    _loading2 "-- Setting VM storage options"
    VM_STORAGE=$(qm config $VM_ID | grep 'unused0' | awk '{ print $2 }')
    ( set -x;qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 "${VM_STORAGE},size=${DISKSIZE}M")
    [[ $? -ne 0 ]] && { _error "Failed to set VM storage options";return 1; }

    _loading2 "-- Resizing VM_ID:$VM_ID disk to ${DISKSIZE}M"
    ( set -x; qm resize ${VM_ID} scsi0 ${DISKSIZE}M )
    [[ $? -ne 0 ]] && { _error "Failed to resize VM disk";return 1; }

    _loading2 "-- Setting SSH Key on VM_ID:$VM_ID with SSH_KEY:$SSH_KEY"
    ( set -x;qm set ${VM_ID} --sshkey ${SSH_KEY} )
    [[ $? -ne 0 ]] && { _error "Failed to set SSH Key";return 1; }

    _notice "Completed creation of VM with ID of $VM_ID"
    _notice "To start the VM run: qm start $VM_ID"
}

# -------------------------------------------------------------------
# -- proxmox_createtemp
# -------------------------------------------------------------------
function _proxmox_createtemp () {
    local STORAGE=$PROXMOX_STORAGE
    _loading "Creating template"

    # -- Set Variables if not set
    if [[ -z ${STORAGE} ]]; then
        STORAGE=$(pvesm status -content images | awk {'if (NR!=1) print $1 '})
    fi
    _loading2 "\OS_RELEASE:$OS_RELEASE BRIDGE:$BRIDGE STORAGE:$STORAGE VM_ID:$VM_ID"
    _debugf "\$OS_RELEASE:$OS_RELEASE \$BRIDGE:$BRIDGE \$STORAGE:$STORAGE \$VM_ID:$VM_ID"

    # -- Download cloudimage
    _proxmox_download_cloudimage $OS_RELEASE
    [[ $? -ne 0 ]] && { _error "Failed to download cloudimage"; return 1; }

    # -- Check if VM_ID is taken
    _loading2 "Checking if VMID $VM_ID is taken"
    QM_LIST=$(qm list | awk '{print $1}')
    if echo "$QM_LIST" | grep -q "$VM_ID"; then
        echo "VMID $VM_ID is taken."
        return 1
    else
        _loading3 "VMID $VM_ID is available."
    fi

    # -- Create VM
    _loading2 "Creating VM with ID:$VM_ID"
    _debugf "qm create ${VM_ID} --memory 2048 --net0 virtio,bridge=${BRIDGE} --name ${NAME}"
    qm create ${VM_ID} --memory 2048 --net0 virtio,bridge=${BRIDGE} --name ${NAME}
    [[ $? -ne 0 ]] && return 1

    # -- Import OS Image
    _loading3 "Importing OS Image"
    _debugf "qm importdisk ${VM_ID} ${IMAGE_FILE_PATH} ${STORAGE}"
    qm importdisk ${VM_ID} ${IMAGE_FILE_PATH} ${STORAGE}
    [[ $? -ne 0 ]] && return 1

    # -- Set VM Options
    _loading2 "Setting VM storage options"
    _debugf "qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:${VM_ID}/vm-${VM_ID}-disk-0.raw"
    qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:${VM_ID}/vm-${VM_ID}-disk-0.raw
    [[ $? -ne 0 ]] && { return 1; _error "Failed to set VM storage options"; }

    # -- Set VM clount-init
    _loading3 "Setting VM cloud-init"
    _debugf "qm set ${VM_ID} --ide2 ${STORAGE}:cloudinit"
    qm set ${VM_ID} --ide2 ${STORAGE}:cloudinit

    # -- Setting up vendor.yaml if exists
    _debugf "qm set ${VM_ID} --cicustom 'vendor=local:snippets/vendor.yaml'"
    if [[ -f /var/lib/vz/snippets/vendor.yaml ]]; then
        qm set ${VM_ID} --cicustom 'vendor=local:snippets/vendor.yaml'
        if [[ $? == 0 ]]; then
            _success "Set VM cloud-init vendor.yaml - $(qm config ${VM_ID} | grep cicustom)"
        else
            _error "Setting VM cloud-init vendor.yaml failed"
            return 1
        fi

    fi

    # -- Set VM boot options
    _loading2 "Setting VM boot options"
    _debugf "qm set ${VM_ID} --boot c --bootdisk scsi0"
    qm set ${VM_ID} --boot c --bootdisk scsi0
    [[ $? -ne 0 ]] && return 1

    # -- Set VM display options
    _loading2 "Setting VM display options"
    _debugf "qm set ${VM_ID} --serial0 socket --vga serial0"
    qm set ${VM_ID} --serial0 socket --vga serial0
    [[ $? -ne 0 ]] && return 1

    # -- Set VM to autoboot
    _loading2 "Setting VM to autoboot"
    _debugf "qm set ${VM_ID} --onboot 1"
    qm set ${VM_ID} --autostart 1
    [[ $? -ne 0 ]] && return 1

    # -- Enable QEMU Guest Agent
    _loading2 "Enabling QEMU Guest Agent"
    _debugf "qm set ${VM_ID} --agent enabled=1"
    qm set ${VM_ID} --agent enabled=1
    [[ $? -ne 0 ]] && return 1

    # -- Create VM template
    _loading2 "Creating VM template"
    _debugf "qm template ${VM_ID}"
    qm template ${VM_ID}
    [[ $? -ne 0 ]] && return 1
}

# -------------------------------------------------------------------
# -- _proxmox_clonetemp
# -------------------------------------------------------------------
function _proxmox_clonetemp () {
    # -- Confirm template exists
    _loading2 "Checking if template ${CLONE_ID} exists"
    _debugf "qm list | grep ${CLONE_ID} | awk {'print \$1 '}"
    CID=$(qm list | grep ${CLONE_ID} | awk {'print $1 '})
    [[ $CLONE_ID != $CID ]] && { _loading2 "Template ${CLONE_ID} does not exist."; return 1; } || { _loading2 "Template ${CLONE_ID} exists."; }

    # -- Clone template
    _loading2 "Cloning template ${CLONE_ID} to ${VM_ID}"

    # -- Check if VM_ID is taken
    _loading3 "Checking if VMID $VM_ID is taken"
    QM_LIST=$(qm list | awk '{print $1}')
    if echo "$QM_LIST" | grep -q "$VM_ID"; then
        echo "VMID $VM_ID is taken."
        return 1
    else
        _loading3 "VMID $VM_ID is available."
    fi

    # -- Clone template
    _loading3 "Cloning ${CLONE_ID} to ${VM_ID} with name ${NAME}"
    _debugf "qm clone ${CLONE_ID} ${VM_ID} --name ${NAME}"
    qm clone ${CLONE_ID} ${VM_ID} --name ${NAME} --full
    if [[ $? == 0 ]]; then
        _success "Cloned ${CLONE_ID} to ${VM_ID} with name ${NAME}"
    else
        _error "Cloning ${CLONE_ID} to ${VM_ID} with name ${NAME} failed"
        return 1
    fi

    # -- Set VM to autoboot
    _loading2 "Setting VM to autoboot"
    _debugf "qm set ${VM_ID} --onboot 1"
    qm set ${VM_ID} --autostart 1
    [[ $? -ne 0 ]] && return 1

    # -- Enable QEMU Guest Agent
    _loading2 "Enabling QEMU Guest Agent"
    _debugf "qm set ${VM_ID} --agent enabled=1"
    qm set ${VM_ID} --agent enabled=1
    [[ $? -ne 0 ]] && return 1

    # -- Check if network mac is set
    _loading3 "Checking if network mac is set"
    if [[ -n $MAC ]]; then
        _loading3 "Setting network to ${MAC}"
        _debugf "qm set ${VM_ID} --net0 virtio,macaddr=${MAC},bridge=${BRIDGE}"
        qm set ${VM_ID} --net0 virtio,macaddr=${MAC},bridge=${BRIDGE}
    fi

    # Checking if IP and GW is set
    _loading3 "Checking if IP and GW is set"
    if [[ -n $IP ]] && [[ -n $GW ]]; then
        # -- Make sure IP has CIDR
        _loading3 "Checking if IP has CIDR"
        if [[ $IP != *"/"* ]]; then
            _loading3 "Adding CIDR to IP"
            IP="${IP}/24"
        fi
        _loading3 "Setting IP to ${IP} and GW to ${GW}"
        _debugf "qm set ${VM_ID} --ipconfig0 ip=${IP},gw=${GW}"
        qm set ${VM_ID} --ipconfig0 ip=${IP},gw=${GW}
    fi

    # -- Change cloud-init default password
    GEN_RAND_PASS=$(genpass-monkey)
    RAND_PASS=${GEN_RAND_PASS:0:6}
    _loading3 "Changing cloud-init default password"
    _debugf "qm set ${VM_ID} --cipassword ${RAND_PASS}"
    qm set ${VM_ID} --cipassword ${RAND_PASS}
    if [[ $? == 0 ]]; then
        _success "Changed cloud-init default password to ${RAND_PASS}"
    else
        _error "Changing cloud-init default password to ${RAND_PASS} failed"
        return 1
    fi
}

# -------------------------------------------------------------------
# -- _proxmox_info
# -------------------------------------------------------------------
function _proxmox_info () {
    _debug_all

    _loading "Proxmox instance infornation"
    echo "Version: $(pveversion)"
    echo "============================"
    echo ""

    _loading "Storage:"
    pvesm status -content images | awk {'if (NR!=1) print $1 '}
    echo "============================"
    echo ""

    _loading "Storage API:"
    # List all storage configurations
    _proxmox_get_storage
    if [[ $? -ne 0 ]]; then
        _error "Failed to get storage - $STORAGE"
    else
        echo "$STORAGE"
    fi
    echo "============================"
    echo ""

    _loading "Network:"
    lshw -class network -short | egrep -v 'tap|fwln|fwpr|fwbr'
    echo "============================"
    echo ""
}

# -------------------------------------------------------------------
# -- _proxmox_create_lxc
# -------------------------------------------------------------------
function _proxmox_create_lxc () {
        # -- Update container template database
        _loading3 "Update container template database"
        pveam update # -- Update Container Template Database
        [[ $? -eq 0 ]] && _loading3 "Container template database updated successfully" || { _error "Container template database update failed"; return 1 }

        # -- Download Ubuntu 22.10 Container Template
        _loading3 "Download Ubuntu 22.10 Container Template"
        pveam download local ubuntu-22.10-standard_22.10-1_amd64.tar.zst # -- Download Ubuntu 22.10 Container Template
        [[ $? -eq 0 ]] && _loading3 "Ubuntu 22.10 Container Template downloaded successfully" || { _error "Ubuntu 22.10 Container Template download failed"; return 1 }

        # -- Create Ubuntu 22.10 Container
        _loading3 "Create Ubuntu 22.10 Container for DHCP on vmbr1 network with ip 10.0.0.2 and 16GB rootfs"
        _debugf "pct create 101 local:vztmpl/ubuntu-22.10-standard_22.10-1_amd64.tar.zst --hostname dhcp --memory 512 --swap 512 --cores 1 --net0 name=eth0,bridge=vmbr1,ip=10.0.0.2/24 --ostype ubuntu --rootfs ${STORAGE}:16 --storage ${STORAGE} --unprivileged 1 --onboot 1"
        pct create 101 local:vztmpl/ubuntu-22.10-standard_22.10-1_amd64.tar.zst --hostname dhcp --memory 512 --swap 512 --cores 1 --net0 name=eth0,bridge=vmbr1,ip=10.0.0.2/24 --ostype ubuntu --rootfs ${STORAGE}:16 --storage ${STORAGE} --unprivileged 1 --onboot 1
        [[ $? -eq 0 ]] && _loading3 "Ubuntu 22.10 Container created successfully" || { _error "Ubuntu 22.10 Container creation failed"; return 1 }
}

# ===============================================
# -- _proxmox_memorygb
# ===============================================
function _proxmox_memorygb () {
    MEM=$1
    # Check if $MEM has G at the end
    if [[ $MEM == *G ]]; then
        _loading3 "Memory $MEM has G at the end, converting to MB"
        # -- Check if MEM is not a number between 1 and 128
        MEM=${MEM%G}
        if ! [[ $MEM =~ ^[0-9]+$ ]]; then
            _error "MEM is not a number between 1 and 128"
            return 1
        elif [[ $MEM -lt 1 ]] || [[ $MEM -gt 128 ]]; then
            _error "MEM is not between 1 and 128"
            return 1
        else
            MEM=$((MEM*1024))
        fi
    else
        # -- Check if MEM is not a number between 512 and 100000
        if ! [[ $MEM =~ ^[0-9]+$ ]]; then
            _error "MEM is not a number"
            return 1
        elif [[ $MEM -lt 512 ]]; then
            _error "MEM is less than 512"
            return 1
        fi
    fi
}