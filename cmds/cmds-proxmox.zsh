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