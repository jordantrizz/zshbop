# -- MOTD

# ----------------
# -- Host MOTD
# ----------------

_cmd_exists host_motd
[[ $? == "0" ]] && { _log "Found host motd"; host_motd }|| _log "No host motd"
