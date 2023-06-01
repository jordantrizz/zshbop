# --
# Proxmox helper commands
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

#####################################################################
#####################################################################

# -------------------------------------------------------------------
# -- proxmox
# -------------------------------------------------------------------
help_proxmox[proxmox]="Proxmox helper"
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
    zparseopts -D -E d=DEBUG dr=DRYRUN name:=NAME memory:=MEM network:=NET storage:=STORAGE disksize:=DISKSIZE os:=OS_RELEASE dhcpnet:=DHCP_NET tempdir:=TEMP_DIR sshkey:=SSH_KEY vmid:=VMID ip:=IP bridge:=BRIDGE
    [[ $DEBUG ]] && DEBUGF="1" || DEBUGF="0"
    NAME=${NAME[2]}
    [[ -z $MEM ]] && MEM="2048" || MEM=${MEM[2]}
    [[ -z $NET ]] && NET="vmbr0" || NET=$NET[2]
    [[ -z $STORAGE ]] && STORAGE="local" || STORAGE=$STORAGE[2]
    [[ -z $DISKSIZE ]] && DISKSIZE="20" || DISKSIZE=$DISKSIZE[2]
    [[ -z $OS_RELEASE ]] && OS_RELEASE="focal" || OS_RELEASE=$OS_RELEASE[2]
    [[ -z $DHCP_NET ]] && DHCP_NET="vmbr0" || DHCP_NET=$DHCP_NET[2]
    [[ -z $TEMP_DIR ]] && TEMP_DIR="/tmp" || TEMP_DIR=$TEMP_DIR[2]
    [[ -z $SSH_KEY ]] && SSH_KEY="$HOME/.ssh/id_rsa.pub" || SSH_KEY=$SSH_KEY[2]
    [[ -z $VMID ]] && { VM_ID=$(pvesh get /cluster/nextid); _debug "\pvesh /cluster/nextid: $VM_ID"} || VMID=$VMID[2]
    [[ -z $IP ]] && IP="dhcp" || IP=$IP[2]
    [[ -z $BRIDGE ]] && BRIDGE="vmbr0" || BRIDGE=$BRIDGE[2]

    _debugf "ALL_ARGS: $ALL_ARGS"
    _debugf "DEBUG: $DEBUG"
    _debugf "DRYRUN: $DRYRUN"
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
    _debugf $REQUIRED_PKG
	_require_pkg $REQUIRED_PKG

    # -- Check command
    if [[ $1 == "createvm" ]]; then
        _debugf "Creating VM"
        _proxmox_check || return 1
        _proxmox_createvm
    elif [[ $1 == "createtemp" ]]; then
        _debugf "Creating template"
        _proxmox_check || return 1
        _proxmox_createtemp
    # -- Clone template
    elif [[ $1 == "clonetemp" ]]; then
        _debugf "Cloning template"
        _proxmox_check || return 1
        _proxmox_clonetemp
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

Commands:
  createvm      - Create VM
  createtemp    - Create template
  clonetemp     - Clone template
  vendorci      - Setup vendor cloudinit.yaml
  info          - Info about Proxmox instance
  help          - This help

Global Options:
  -d            - Debug mode
  -dr           - Dry run

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
    -vmid [vmid]              VM ID to use (Default: 9000)
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
    if [[ $DRYRUN == "1" ]]; then
        _loading3 "Doing a dryrun"
	else
        # -- Ensure commands are present
        [[ -x $(command -v pvesh) ]] && _success "Proxmox is installed" || { _error "No pvesh present, not running proxmox or other issue."; return 1 }
        [[ -x $(command -v lshw) ]] && _success "lshw is installed" || { _error "No lshw present, required."; return 1 }
        [[ -x $(command -v virt-customize) ]] && _success "lshw is installed" || { _error "No virt-customize present, required."; return 1 }
    fi
}

# -------------------------------------------------------------------
# -- _proxmox_download_cloudimage
# -------------------------------------------------------------------
function _proxmox_download_cloudimage () {
    # -- Check if $OS is valid
    _loading2 "Checking if $OS is a valid OS"
    AVAIL_OS=("focal" "bionic" "jammy")
    _if_marray "$OS" AVAIL_OS
    if [[ $MARRAY_VALID == "1" ]]; then
        _error "Couldn't get Ubuntu Image for $OS"
        return
    else
        _loading2 "OS: $OS is valid"
    fi
    echo ""

    # -- Download OS Image
    IMAGE_FILE="${OS}-server-cloudimg-amd64.img"
    IMAGE_URL="https://cloud-images.ubuntu.com/focal/current/${}"
    IMAGE_FILE_PATH="${TEMP_DIR}/${IMAGE_FILE}"
    
    _loading3 "Fetching $OS Image from $IMAGE_URL into $TEMP_DIR"
    _loading4 "Checking if $IMAGE_FILE exists in $TEMP_DIR"
    if [[ -f ${IMAGE_FILE_PATH} ]]; then
        _loading4 "Found $IMAGE_FILE_PATH"
        _loading4 "Checking MD5"
        IMAGE_URL_MD5=$(curl -s https://cloud-images.ubuntu.com/$OS/current/MD5SUMS | grep "$OS-server-cloudimg-amd64.img" | awk {' print $1 '})
        _loading4 "\$OS_URL_MD5: $IMAGE_URL_MD5"
        IMAGE_FILE_MD5=$(md5sum $IMAGE_FILE_PATH | awk {'print $1'})
        _loading4 "\$OS_FILE_MD5: $IMAGE_FILE_MD5"
        if [[ $IMAGE_URL_MD5 == $IMAGE_FILE_MD5 ]]; then
            _loading4 "Local file $IMAGE_FILE_PATH matches remote MD5, continuing build"
        else
            _error "Local file $IMAGE_FILE_PATH MD5 does not match remote MD5."
            _loading4 "Downloading $IMAGE_URL into $TEMP_DIR"
            _debugf "curl --output $IMAGE_FILE_PATH $IMAGE_URL"
            curl --output $IMAGE_FILE_PATH $IMAGE_URL
        fi
    else
        _debugf "curl --output $IMAGE_FILE_PATH $IMAGE_URL"
        curl --output $IMAGE_FILE_PATH $IMAGE_URL
    fi
    echo ""
}

# -------------------------------------------------------------------
# -- proxmox_createvm
# -------------------------------------------------------------------
function_proxmox_createvm () {
    # -- Check if storage exists
    IFS=$'\n' proxmox_STORAGE=($(pvesm status | awk {' print $1 '}))
    _if_marray "$STORAGE" proxmox_STORAGE
    if [[ $MARRAY_VALID == "1" ]]; then
        _error "Storage $STORAGE doesn't exist, type pmox info"            
        return
    fi

    # -- Download cloudimage
    _proxmox_download_cloudimage
    
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
    --cpu host \
    --agent enabled=1,fstrim_cloned_disks=1 \
    --cicustom "user=local:/userconfig.yaml"
    )
    ( set -x;qm importdisk $VM_ID /tmp/${OS_FILE} ${STORAGE} )
    ( set -x;qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${VM_ID}-disk-0,size=${DISKSIZE}M )
    ( set -x; qm resize ${VM_ID} scsi0 ${DISKSIZE}M )
    ( set -x;qm set ${VM_ID} --sshkey ${SSH_KEY} )

    _notice "Completed creation of VM with ID of $VM_ID"
    _notice "To start the VM run: qm start $VM_ID"
}

# -------------------------------------------------------------------
# -- proxmox_createtemp
# -------------------------------------------------------------------
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

    # -- Download cloudimage
    _proxmox_download_cloudimage

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
    _loading3 "Importing OS Image"
    _debugf "qm importdisk ${VM_ID} ${IMAGE_FILE_PATH} ${PROXMOX_STORAGE}"
    qm importdisk ${VM_ID} ${IMAGE_FILE_PATH} ${PROXMOX_STORAGE}
    [[ $? -ne 0 ]] && return 1

    # -- Set VM Options
    _loading2 "Setting VM storage options"
    _debugf "qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:${VM_ID}/vm-${VM_ID}-disk-0.raw"
    qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:${VM_ID}/vm-${VM_ID}-disk-0.raw
    [[ $? -ne 0 ]] && return 1

    # -- Set VM Cloudinit
    _loading3 "Setting VM cloudinit"
    _debugf "qm set ${VM_ID} --ide2 ${PROXMOX_STORAGE}:cloudinit"
    _debugf "qm set ${VM_ID} --cicustom 'vendor=local:snippets/vendor.yaml'"
    qm set ${VM_ID} --ide2 ${PROXMOX_STORAGE}:cloudinit
    qm set ${VM_ID} --cicustom 'vendor=local:snippets/vendor.yaml'
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

# -------------------------------------------------------------------
# -- _proxmox_clonetemp
# -------------------------------------------------------------------
function _proxmox_clonetemp () {
    # -- Confirm template exists        
    _loading2 "Checking if template ${CLONE_ID} exists"
    _debugf "qm list | grep ${CLONE_ID} | awk {'print \$1 '}"
    CID=$(qm list | grep ${CLONE_ID} | awk {'print $1 '})
    [[ $CLONE_ID != $CID ]] && { _loading2 "Template ${CLONE_ID} does not exist."; return 1; } || { _loading2 "Template ${CLONE_ID} exists."; }
}

# -------------------------------------------------------------------
# -- _proxmox_info
# -------------------------------------------------------------------
function _proxmox_info () {
    _debug_all
    _loading "Proxmox instance infornation"
    echo "----------------------------"
    echo "Version: $(pveversion)"
    echo "Storage: $(pvesm status -content images | awk {'if (NR!=1) print $1 '})"     
    echo "Network: $(lshw -class network -short | egrep -v 'tap|fwln|fwpr|fwbr')"
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
        _debugf "pct create 101 local:vztmpl/ubuntu-22.10-standard_22.10-1_amd64.tar.zst --hostname dhcp --memory 512 --swap 512 --cores 1 --net0 name=eth0,bridge=vmbr1,ip=10.0.0.2/24 --ostype ubuntu --rootfs ${PROXMOX_STORAGE}:16 --storage ${PROXMOX_STORAGE} --unprivileged 1 --onboot 1"
        pct create 101 local:vztmpl/ubuntu-22.10-standard_22.10-1_amd64.tar.zst --hostname dhcp --memory 512 --swap 512 --cores 1 --net0 name=eth0,bridge=vmbr1,ip=10.0.0.2/24 --ostype ubuntu --rootfs ${PROXMOX_STORAGE}:16 --storage ${PROXMOX_STORAGE} --unprivileged 1 --onboot 1
        [[ $? -eq 0 ]] && _loading3 "Ubuntu 22.10 Container created successfully" || { _error "Ubuntu 22.10 Container creation failed"; return 1 }
}

# -------------------------------------------------------------------
# -- _proxmox_vendorci
# -------------------------------------------------------------------
function _proxmox_vendorci () {
    # -- Create vendor.yaml file
    _loading "Creating vendor.yaml file at /var/lib/vz/snippets"
    if [[ ! -d /var/lib/vz/snippets ]]; then
        _error "/var/lib/vz/snippets doesn't exist."
        exit 1
    else
        _loading3 "Found /var/lib/vz/snippets, creating /var/lib/vz/snippets/vendor.yaml file"
cat << EOF > /var/lib/vz/snippets/vendor.yaml
#cloud-config
users:
  - name: root
    ssh_authorized_keys:
      - ssh_authorized_keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIyaSjx2adBrDbvYMTVoWnUfog4UsZK67wI3OumnArIDlzEjwse3aOx8dj79R1G0wTLrjKEu1kAsO0jSoGdkV4Lujub4oLm3j240nn1HhXHUWfv3ZqU7eSThBI7lCuHwDcj0r5nJm5GkCtLLplnweLqLxfd8fgPj+a8Cey4euxAE3rtSpQI9M3mrcAUtw9TgXGK7N/tgA9yBSxCM5GT4AvKjbedoxEvAH7QfqUrSoF4zc85EvwjS8QmYdPaVahyYafuJOT2KsmiCFJWAh/rHQuxcG5352svOJRQaaS/LbOAsAz3FwcxulagwefAW7C7h2+j5i2q0rMCAeQ34cS2HFD root@srv01

package_update: true
package_upgrade: true
packages:
  - joe
  - zsh
  - qemu-guest-agent

ssh_pwauth: false
disable_root: false

runcmd:
  - systemctl start qemu-guest-agent

output:
  all: '| tee -a /var/log/cloud-init-output.log'
EOF
    fi
}

# -------------------------------------------------------------------
# -- proxmox-backup.sh
# -------------------------------------------------------------------
help_proxmox[proxmox-backup.sh]='Backup proxmox database'
