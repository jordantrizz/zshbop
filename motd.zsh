# -- MOTD

# ----------------
# -- Host MOTD
# ----------------

_cexists host_motd
if [[ $? == "0" ]]; then
    _loading "Found host motd"
    host_motd
else
    _notice "No host motd"
fi

# ----------------
# -- GridPane
# ----------------
if [[ -f /root/grid.id ]]; then
    _loading "Running GridPane CP - type help gridpane for more commands"
    source "${ZBR}/motd/motd-gp.zsh"
    motd_gp
fi

# ----------------
# -- Runcloud
# ----------------
if [[ -d /home/runcloud/webapps ]]; then
    _loading "Running Runcloud CP - type help runcloud for more commands"
    source "${ZBR}/motd/motd-runcloud.zsh"
    motd_runcloud
fi