# --
# Proxmox
# --
_debug " -- Loading ${(%):-%N}"
help_files[proxmox]='Proxmox commands'
typeset -gA help_proxmox

# -- proxmox-restart
help_proxmox[proxmox-restart]="Restart Proxmox services"
function proxmox-restart () {
    _loading " -- Running proxmox-restart"
    systemctl restart pve-cluster pvedaemon pvestatd pveproxy pve-ha-lrm pve-firewall pvefw-logger
}



# -------------------
# -- register proxmox
# -------------------
help_proxmox[proxmox]="Proxmox helper"
alias pmox='proxmox'
proxmox () {
        if [[ $1 == "help" ]] || [[ -z $1 ]]; then
                proxmox_help
        elif [[ -n $1 ]]; then
	        _debug "-- Running pmox $1"
                proxmox_init $@
        fi
}

# -- proxmox_init
proxmox_init () {
    # -- debug
    _debug_all
    ALLARGS="$@"
    zparseopts -D -E d=DEBUG -name=NAME -memory=MEM -network=NET -storage=STORAGE -disksize=DISKSIZE -os=OS_RELEASE -dhcpnet=DHCP_NET -tempdir=TEMP_DIR -sshkey=SSH_KEY -vmid=VMID -ip=IP -bridge=BRIDGE
    [[ $DEBUG ]] && DEBUGF="1" || DEBUGF="0"
    _debugf "ALL_ARGS: $ALL_ARGS"
    _debugf "DEBUG: $DEBUG"
    _debugf "HELP: $HELP"
    _debugf "NAME: $NAME"
    _debugf "MEM: $MEM"
    _debugf "NET: $NET"
    _debugf "STORAGE: $STORAGE"
    _debugf "DISKSIZE: $DISKSIZE"
    _debugf "OS_RELEASE: $OS_RELEASE"
    _debugf "DHCP_NET: $DHCP_NET"
    _debugf "TEMP_DIR: $TEMP_DIR"
    _debugf "SSH_KEY: $SSH_KEY"
    _debugf "VMID: $VMID"
    _debugf "IP: $IP"
    _debugf "BRIDGE: $BRIDGE"

    REQUIRED_PKG=('curl' 'libguestfs-tools')
    _debug $REQUIRED_PKG
	_require_pkg $REQUIRED_PKG

    # -- Check command
    if [[ $1 == "createvm" ]]; then
        _proxmox_check || return 1
        _proxmox_createvm
    elif [[ $1 == "createtemp" ]]; then
        _proxmox_check || return 1
        _proxmox_createtemp
    elif [[ $1 == "clonetemp" ]]; then
        _proxmox_check || return 1
        _proxmox_clonetemp
    elif [[ $1 == "info" ]]; then
        _proxmox_check || return 1
        _proxmox_info
    elif [[ $1 == help ]]; then
        _proxmox_help
    else
        _proxmox_help
    fi

}

# -- proxmox_help
_proxmox_help () {
	_loading "Proxmox Helper"
    echo \
"
Usage: pmox <command> <options>

Commands:
  createvm      - Create VM
  createtemp    - Create template
  clonetemp     - Clone template
  info          - Info about Proxmox instance
  help          - This help

Global Options:
  -d            - Debug mode

Command Options:

  createvm <options>
  ------------------
    -name <name>              Name of the VM
    -memory <memory>          Memory of VM in MB (Default: 2GB)
    -network <network>        Network bridge to use (Default: vmbr0)
    -storage <storage>        Storage location (Autodetect)
    -disksize <disksize>      Disk size in MB (Default: 20GB)
    -os <os>                  bionic,focal,jammy (Default: focal)
    -dhcpnet [dhcpnet]        If you have a local network with dhcp, the bridge it's on.
    -tempdir [tempdir]        Setup temporary directory for download for cloudimage, optional.
    -sshkey [sshkey]          SSH key to add to VM, optional. (Default: ~/.ssh/id_rsa.pub)
    -vmid [vmid]              VM ID to use, (Default: random)
	
	Example: createvm -name server -memory 2048 -network vmbr0 -storage local -disksize 80 -os focal
  
  createtemp <options>
  --------------------
    -os <os>                  bionic,focal,jammy, default focal
    -bridge <bridge>          Network bridge to use, default vmbr0
    -storage <storage>        Storage location, default local-lvm
    -vmid <vmid>              VM ID to use, default 9000

  clonetemp <options>
  -------------------
    -name <name>              Name of the VM
    -vmid [vmid]              VM ID to use (Default: random)
    -ip [ip]                  IP address to use (Default: dhcp)

  OS:
    Ubuntu 22.04 LTS = jammy
    Ubuntu 20.04.4 LTS = focal
    Ubuntu 18.04.6 LTS = bionic
    "
}

# -- check if proxmox is installed and other checks
function _proxmox_check () {
    # -- check for pvesh
	[[ -x $(command -v pvesh) ]] && _success "Proxmox is installed" || { _error "No pvesh present, not running proxmox"; return 1 }
    [[ -x $(command -v lshw) ]] && _success "lshw is installed" || { _error "No lshw present, required for info command"; return 1 }
}

# -- proxmox_createvm
_proxmox_createvm () {    


    NAME=$2
    MEM=$3
    NET=$4
    STORAGE=$5
    DISKSIZE=$6
    OS_RELEASE=$7
    DHCP_NET="$8"

    # -- Clear variables
    OS_IMG=""

    if [[ -n $9 ]]; then
        TEMP_DIR=$9
    else
        TEMP_DIR="/tmp"
    fi
    _debug "\$TEMP_DIR=$TEMP_DIR"

    _debug "\$NAME:$NAME \$MEM:$MEM \$NET:NET \$STORAGE:$STORAGE \$DISKSIZE:$DISKSIZE \$OS_RELEASE:$OS_RELEASE \$DHCP_NET:$DHCP_NET"

    if [[ -z $NAME ]] || [[ -z $MEM ]] || [[ -z $NET ]] || [[ -z $STORAGE ]] || [[ -z $DISKSIZE ]] || [[ -z $OS_RELEASE ]]; then
        _proxmox_help
    else
        # -- Check if storage exists
        IFS=$'\n' proxmox_STORAGE=($(pvesm status | awk {' print $1 '}))
        _if_marray "$STORAGE" proxmox_STORAGE
        if [[ $MARRAY_VALID == "1" ]]; then
            _error "Storage $STORAGE doesn't exist, type pmox info"            
            return
        fi

        # -- check if provided OS release is correct
        AVAIL_RELEASES=("focal" "bionic" "jammy")
        _if_marray "$OS_RELEASE" AVAIL_RELEASES
        if [[ $MARRAY_VALID == "1" ]]; then
            _error "Couldn't get OS Image"
            return
        fi

        # -- set $OS_URL and $OS_FILE
        OS_URL="https://cloud-images.ubuntu.com/$OS_RELEASE/current/$OS_RELEASE-server-cloudimg-amd64.img"
        OS_FILE="$OS_RELEASE-server-cloudimg-amd64.img"

        # -- Check if $OS_FILE exists in $TEMP_DIR
        _debug "Checking if $OS_FILE exists in $TEMP_DIR"
        if [[ -e $TEMP_DIR/$OS_FILE ]]; then
            echo "-- $OS_FILE already in $TEMP_DIR"
            echo "-- Checking MD5"
            OS_URL_MD5=$(curl -s https://cloud-images.ubuntu.com/$OS_RELEASE/current/MD5SUMS | grep "$OS_RELEASE-server-cloudimg-amd64.img" | awk {' print $1 '})
            _debug "\$OS_URL_MD5: $OS_URL_MD5"
            OS_FILE_MD5=$(md5sum $TEMP_DIR/$OS_FILE | awk {'print $1'})
            _debug "\$OS_FILE_MD5:$OS_FILE_MD5"

            # -- Check MD5
            if [[ $OS_URL_MD5 == $OS_FILE_MD5 ]]; then
                echo "-- Local file matches remote MD5, continuing build"
            else
                _error "Local file MD5 does not match remote MD5."
                echo "-- Downloading $OS_URL into $TEMP_DIR"
                curl $OS_URL --output $TEMP_DIR/$OS_FILE
            fi
        else
            echo "-- Downloading $OS_URL into $TEMP_DIR"
            curl $OS_URL --output $TEMP_DIR/$OS_FILE
        fi
        
        # -- Enable internal nic with DHCP
        if [[ -n $DHCP_NET ]]; then
            DHCP_NET_INT="--net1"
            DHCP_NET_QM="virtio,bridge=${DHCP_NET},firewall=1"
            DHCP_IP="--ipconfig1"
            DHCP_IP_CFG="ip=dhcp"
        else
            DHCP_NET_INT=""
            DHCP_NET_QM=""
        fi

        # -- Insert guest tools into image
        ( set -x; virt-customize -a $TEMP_DIR/$OS_FILE --install qemu-guest-agent )

        # -- Start build
        VM_ID=$(set -x;pvesh get /cluster/nextid)
        _debug "\$VM_PID:$VM_ID"
        
        # -- QM Config Variables

        # -- Run QM Command
        echo "-- Creating VM with ID:$VM_ID"
        (set -x;qm create $VM_ID --name $NAME --memory $MEM \
        $DHCP_NET_INT $DHCP_NET_QM \
        $DHCP_IP $DHCP_IP_CFG \
        --net0 virtio,bridge=$NET,firewall=1 \
        --bootdisk scsi0 \
        --scsihw virtio-scsi-pci \
        --ide2 media=cdrom,file=none \
        --ide0 ${STORAGE}:cloudinit,size=4M \
        --boot cdn \
        --ostype l26 \
        --onboot 1 \
        --cpu host
        --agent enabled=1,fstrim_cloned_disks=1 \
        #--cicustom "user=local:/userconfig.yaml" \
        )
        ( set -x;qm importdisk $VM_ID /tmp/${OS_FILE} ${STORAGE} )
        ( set -x;qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${VM_ID}-disk-0,size=${DISKSIZE}M )
        ( set -x; qm resize ${VM_ID} scsi0 ${DISKSIZE}M )
        ( set -x;qm set ${VM_ID} --sshkey ${SSH_KEY} )

        _notice "Completed creation of VM with ID of $VM_ID"
    fi
}

# -- proxmox_createtemp
# $OS $BRIDGE $STORAGE $VM_ID
function _proxmox_createtemp () {
    _loading "Creating template"

    # -- Set Variables if not set
    [[ -z ${VM_ID} ]] && VM_ID="9000"
    [[ -z ${OS} ]] && OS="focal"
    [[ -z ${BRIDGE} ]] && BRIDGE="vmbr0"
    if [[ -z ${STORAGE} ]]; then
        STORAGE=$(pvesm status -content images | awk {'if (NR!=1) print $1 '})
    fi
    _loading2 "OS:$OS BRIDGE:$BRIDGE STORAGE:$STORAGE VM_ID:$VM_ID"
    _debugf "\$OS:$OS \$BRIDGE:$BRIDGE \$STORAGE:$STORAGE \$VM_ID:$VM_ID"

    # -- Check if $OS is valid
    _loading2 "Checking if $OS is a valid OS"
    AVAIL_OS=("focal" "bionic" "jammy")
    _if_marray "$OS" AVAIL_OS
    if [[ $MARRAY_VALID == "1" ]]; then
        _error "Couldn't get OS Image"
        return
    else
        _loading2 "OS: $OS is valid"
    fi
    echo ""

    # -- Download OS Image
    IMAGE_FILE="${OS}-server-cloudimg-amd64.img"
    IMAGE_URL="https://cloud-images.ubuntu.com/focal/current/${IMAGE_FILE}"
    TEMP_DIR="/tmp"
    _loading2 "Fetching $OS Image from $IMAGE_URL into $TEMP_DIR"
    _loading3 "Checking if $IMAGE_FILE exists in $TEMP_DIR"
    if [[ -f ${TEMP_DIR}/${IMAGE_FILE} ]]; then
        _loading3 "$IMAGE_FILE already in $TEMP_DIR"
        _loading3 "Checking MD5"
        OS_URL_MD5=$(curl -s https://cloud-images.ubuntu.com/$OS_RELEASE/current/MD5SUMS | grep "$OS_RELEASE-server-cloudimg-amd64.img" | awk {' print $1 '})
        _loading4 "\$OS_URL_MD5: $OS_URL_MD5"
        OS_FILE_MD5=$(md5sum $TEMP_DIR/$OS_FILE | awk {'print $1'})
        _loading4 "\$OS_FILE_MD5:$OS_FILE_MD5"
        if [[ $OS_URL_MD5 == $OS_FILE_MD5 ]]; then
            _loading4 "Local file matches remote MD5, continuing build"
        else
            _error "Local file MD5 does not match remote MD5."
            _loading4 "Downloading $IMAGE_URL into $TEMP_DIR"
            _debugf "curl --output /tmp/$IMAGE_FILE $IMAGE_URL"
            curl --output /tmp/$IMAGE_FILE $IMAGE_URL
        fi
    else
        _debugf "curl --output /tmp/$IMAGE_FILE $IMAGE_URL"
        curl --output /tmp/$IMAGE_FILE $IMAGE_URL
    fi
    echo ""

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
    _debugf "qm create ${VM_ID} --memory 2048 --net0 virtio,bridge=${BRIDGE}"
    qm create ${VM_ID} --memory 2048 --net0 virtio,bridge=${BRIDGE}
    [[ $? -ne 0 ]] && return 1

    # -- Import OS Image
    _loading2 "Importing OS Image"
    _debugf "qm importdisk ${VM_ID} /tmp/${IMAGE_FILE} ${STORAGE}"
    qm importdisk ${VM_ID} /tmp/${IMAGE_FILE} ${STORAGE}
    [[ $? -ne 0 ]] && return 1

    # -- Set VM Options
    _loading2 "Setting VM storage options"
    _debugf "qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:${VM_ID}/vm-${VM_ID}-disk-0.raw"
    qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:${VM_ID}/vm-${VM_ID}-disk-0.raw
    [[ $? -ne 0 ]] && return 1

    # -- Set VM Options
    _loading2 "Setting VM cloudinit"
    _debugf "qm set ${VM_ID} --ide2 ${STORAGE}:cloudinit"
    qm set ${VM_ID} --ide2 ${STORAGE}:cloudinit
    [[ $? -ne 0 ]] && return 1

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

    # -- Create VM template
    _loading2 "Creating VM template"
    _debugf "qm template ${VM_ID}"
    qm template ${VM_ID}
    [[ $? -ne 0 ]] && return 1
}


# -- proxmox_info
_proxmox_info () {
    _debug_all
    _debug_all
    _banner_green "Proxmox instance infornation"
    echo "----------------------------"
    echo "Version: $(pveversion)"
    echo "Storage: $(pvesm status -content images | awk {'if (NR!=1) print $1 '})"     
    echo "Network: $(lshw -class network -short | egrep -v 'tap|fwln|fwpr|fwbr')"
}

# -- _proxmox_create_lxc
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
        _debugf "pct create 101 local:vztmpl/ubuntu-22.10-standard_22.10-1_amd64.tar.zst --hostname dhcp --memory 512 --swap 512 --cores 1 --net0 name=eth0,bridge=vmbr1,ip=10.0.0.2/24 --ostype ubuntu --rootfs ${PROXMOX_STORAGE}:16 --storage ${PROXMOX_STORAGE} --unprivileged 1 --onboot 1"
        pct create 101 local:vztmpl/ubuntu-22.10-standard_22.10-1_amd64.tar.zst --hostname dhcp --memory 512 --swap 512 --cores 1 --net0 name=eth0,bridge=vmbr1,ip=10.0.0.2/24 --ostype ubuntu --rootfs ${PROXMOX_STORAGE}:16 --storage ${PROXMOX_STORAGE} --unprivileged 1 --onboot 1
        [[ $? -eq 0 ]] && _loading3 "Ubuntu 22.10 Container created successfully" || { _error "Ubuntu 22.10 Container creation failed"; return 1 }
}

# -- proxmox-backup.sh
help_proxmox[proxmox-backup.sh]='Backup proxmox database'
