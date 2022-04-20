# --
# Proxmox commands
#
# Example help: help_pmox[pmox]='Command description'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[pmox]='Proxmox commands'

# - Init help array
typeset -gA help_pmox

# -- register pmox
pmox () {
        if [[ $1 == "help" ]] || [[ ! $1 ]]; then
                help pmox
        elif [[ $1 ]]; then
	        _debug "-- Running pmox $1"
                pmox_cmd=(pmox_${1})
                $pmox_cmd $@
        fi
}

# -- createvm
help_pmox[createvm]='Create VM'
pmox_createvm () {
    #-- debug
    _debug_all
    _debug_function

    #-- check for pvesh
    if [[ $(_cexists pvesh) ]]; then
        if [[ $ZSH_DEBUG == "0" ]]; then
            _error "No pvesh present, not running proxmox"
            return
        fi
    fi

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

    if [[ $9 ]]; then
        TEMP_DIR=$9
    else
        TEMP_DIR="/tmp"
    fi
    _debug "\$TEMP_DIR=$TEMP_DIR"

    _debug "\$NAME:$NAME \$MEM:$MEM \$NET:NET \$STORAGE:$STORAGE \$DISKSIZE:$DISKSIZE \$OS_RELEASE:$OS_RELEASE \$DHCP_NET:$DHCP_NET"

    # -- Usage
    if [[ ! $NAME ]] || [[ ! $MEM ]] || [[ ! $NET ]] || [[ ! $STORAGE ]] || [[ ! $DISKSIZE ]] || [[ ! $OS_RELEASE ]]; then
       echo "Usage: createvm <name> <memory> <network-bridge> <storage> <disksize> <os> [dhcpnet] [tempdir]"
       echo ""
       echo "<disksize>     - Disk size in MB"
       echo "<os>           - bionic,focal "
       echo "[dhcpnet]      - If you have a local network with dhcp, the bridge it's on."
       echo "[tempdir]      - Setup temporary directory for download for cloudimage, optional."
       echo ""
       echo "Example: createvm server 2048 vmbr0 storage-lvm 80 focal"
       echo ""
    else
        # -- check if provided OS release is correct
        AVAIL_RELEASES=("focal" "bionic")
        _if_marray "$OS_RELEASE" AVAIL_RELEASES
        _debug "\$CHECK_OS = $CHECK_OS"
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
                return
            fi
        else
            echo "-- Downloading $OS_URL into $TEMP_DIR"
            curl $OS_URL --output $TEMP_DIR/$OS_FILE
        fi
        
        # -- Enable internal nic with DHCP
        if [[ $DHCP_NET ]]; then
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

