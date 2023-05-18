# --
# Proxmox
# --
_debug " -- Loading ${(%):-%N}"
help_files[proxmox]='Proxmox commands'
typeset -gA help_proxmox

# -- register proxmox
alias pmox='proxmox'
proxmox () {
        if [[ $1 == "help" ]] || [[ -z $1 ]]; then
                proxmox_help
        elif [[ -n $1 ]]; then
	        _debug "-- Running pmox $1"
                proxmox_init $@
        fi
}

# -- pmox
help_proxmox[help]='Help'
proxmox_help () {
	_loading "Proxmox Helper"
    echo \
"
Usage: pmox <command> <options>

Commands:
  createvm      - Create VM
  createtemp    - Create template
  info          - Info about Proxmox instance

Options:

  createvm <name> <memory> <network> <storage> <disksize> <os> [dhcpnet] [tempdir]

    <name>              - Name of the VM
	<memory>            - Memory of VM in MB
	<network>           - Network bridge to use
    <storage>           - Storage location
	<disksize>          - Disk size in MB
	<os>                - bionic,focal,jammy
	[dhcpnet]           - If you have a local network with dhcp, the bridge it's on.
	[tempdir]           - Setup temporary directory for download for cloudimage, optional.
	
	Example: createvm server 2048 vmbr0 storage-lvm 80 focal
  
  createtemp <os> <bridge> <storage> <vmid>
    <os>                - bionic,focal,jammy, default focal
    <bridge>            - Network bridge to use, default vmbr0
    <storage>           - Storage location, default local-lvm
    <vmid>              - VM ID to use, default 9000

    OS:
      Ubuntu 22.04 LTS = jammy
      Ubuntu 20.04.4 LTS = focal
      Ubuntu 18.04.6 LTS = bionic"
}

# -- proxmox_init
proxmox_init () {
    # -- debug
    _debug_all
    ALLARGS="$@"
    zparseopts -D -E d=DEBUG
    [[ DEBUG ]] || DEBUGF=1
    _debugf "ALLARGS: $ALLARGS"
    
    REQUIRED_PKG=('curl' 'libguestfs-tools')
    _debug $REQUIRED_PKG
	_require_pkg $REQUIRED_PKG

    # -- check for pvesh
	_cexists pvesh
    if [[ $? == "1" ]]; then        
        _error "No pvesh present, not running proxmox"
    fi

    # -- Check command
    if [[ $1 == "createvm" ]]; then
        proxmox_createvm $@
    elif [[ $1 == "createtemp" ]]; then
        proxmox_createtemp $@
    elif [[ $1 == "info" ]]; then
        proxmox-info
    else
        proxmox_help
    fi
}    

# -- proxmox_createvm
help_proxmox[createvm]='Create VM'
proxmox_createvm () {
    _debug_all
    # -- inputs
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
        proxmox_help
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
        ( set -x;qm set ${VM_ID} --sshkey ~/.ssh/id_rsa.pub )

        _notice "Completed creation of VM with ID of $VM_ID"
    fi
}

# -- proxmox_createtemp
# $OS $BRIDGE $STORAGE $VM_ID
help_proxmox[proxmox_createtemp]='Create a template from a VM'
function proxmox_createtemp () {        
    [[ -z ${VM_ID} ]] || VM_ID="9000"
    [[ -z ${OS} ]] || OS="focal"
    [[ -z ${BRIDGE} ]] || BRIDGE="vmbr0"
    [[ -z ${STORAGE} ]] || STORAGE="local-lvm"    
    _debugf "\$OS:$OS \$BRIDGE:$BRIDGE \$STORAGE:$STORAGE \$VM_ID:$VM_ID"

    IMAGE_FILE="${OS}-server-cloudimg-amd64.img"
    IMAGE_URL="https://cloud-images.ubuntu.com/focal/current/${IMAGE_FILE}"
    curl -o /tmp/$IMAGE_FILE $IMAGE_URL
    qm create ${VM_ID} --memory 2048 --net0 virtio,bridge=${BRIDGE}
    qm importdisk ${VM_ID} /tmp/${IMAGE_FILE} ${STORAGE}
    qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-9000-disk-0
    qm set ${VM_ID} --ide2 ${STORAGE}:cloudinit
    qm set ${VM_ID} --boot c --bootdisk scsi0
    qm set ${VM_ID} --serial0 socket --vga serial0
    qm template ${VM_ID}
}


# -- proxmox-info
help_proxmox[proxmox-info]='Info about Proxmox instance'
proxmox-info () {
    _debug_all
    _debug_all
    _banner_green "Proxmox instance infornation"
    echo "----------------------------"
    _banner_green "  -- Version"
    pveversion
    _banner_green " -- Storage"
    cat /etc/pve/storage.cfg
    _banner_green " -- Network"
    lshw -class network -short | egrep -v 'tap|fwln|fwpr|fwbr'
}

# -- proxmox-backup.sh
help_proxmox[proxmox-backup.sh]='Backup proxmox database'
