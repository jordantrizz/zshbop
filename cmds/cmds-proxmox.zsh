# --
# Proxmox helper commands
# --
_debug " -- Loading ${(%):-%N}"
help_files[proxmox]='Proxmox commands'
typeset -gA help_proxmox

help_proxmox[proxmox]="Proxmox helper"

# -- proxmox-restart
help_proxmox[proxmox-restart]="Restart Proxmox services"
function proxmox-restart () {
    _loading " -- Running proxmox-restart"
    systemctl restart pve-cluster pvedaemon pvestatd pveproxy pve-ha-lrm pve-firewall pvefw-logger
}

# -------------------------------------------------------------------
# -- proxmox-backup.sh
# -------------------------------------------------------------------
help_proxmox[proxmox-backup.sh]='Backup proxmox database'
function proxmox-backup.sh () {
    _loading " -- Running proxmox-backup.sh"
    /usr/bin/proxmox-backup.sh
}

# =====================================
# -- proxmox-memory-report
# =====================================
help_proxmox[proxmox-memory-report]='Get memory report for Proxmox'
function proxmox-memory-report () {
    _loading "Running proxmox-memory-report"
    # Get a list of all vms
    local VMS=($(qm list | awk 'NR>1 {print $1}'))
    local TOTAL_MEMORY=0
    local TOTAL_USED=0
    local TOTAL_FREE=0

    # Loop through each vm and get memory usage
    local OUTPUT="VM\tName\tTotal Memory\tUsed Memory\tFree Memory\n"
    OUTPUT+="--\t----\t------------\t-----------\t----------\n"
    for VM in $VMS; do
        local NAME=$(qm config $VM | grep name | awk '{print $2}')
        local MEMORY=$(qm config $VM | grep memory | awk '{print $2}')
        # Used
        local BALLOON=$(qm-monitor $VM info balloon | grep balloon:)
        if [[ -n "$BALLOON" ]]; then
            # Extract total_mem and free_mem (both in MB)
            local TOTAL_MEM=$(echo $BALLOON | sed -n 's/.*total_mem=\([0-9]*\).*/\1/p')
            local FREE_MEM=$(echo $BALLOON | sed -n 's/.*free_mem=\([0-9]*\).*/\1/p')
            if [[ -n "$TOTAL_MEM" && -n "$FREE_MEM" ]]; then
                USED=$((TOTAL_MEM - FREE_MEM))
                FREE=$FREE_MEM
            fi
        fi
        local FREE=$((MEMORY - USED))
        TOTAL_MEMORY=$((TOTAL_MEMORY + MEMORY))
        TOTAL_USED=$((TOTAL_USED + USED))
        TOTAL_FREE=$((TOTAL_FREE + FREE))
        OUTPUT+="$VM\t$NAME\t$MEMORY\t$USED\t$FREE\n"
    done
    echo "$OUTPUT" | column -t -s $'\t'
    echo "-----------------------------------------------------"
    echo "Total VM Memory: $TOTAL_MEMORY"
    TOTAL_SYS_MEMORY=$(free -m | awk '/^Mem:/ {print $2}')
    echo "Total SYS Memory: $TOTAL_SYS_MEMORY"
    echo "% Available: $((100 * (TOTAL_SYS_MEMORY - TOTAL_MEMORY) / TOTAL_SYS_MEMORY))%"
    echo "-----------------------------------------------------"
    echo "Total Used: N/A"
    echo "Total Free: N/A"
    _success "Proxmox memory report generated successfully."
}