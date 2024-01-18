# -- MOTD

# ----------------
# -- Host MOTD
# ----------------

_cmd_exists host_motd
[[ $? == "0" ]] && { _loading "Found host motd"; host_motd }|| _notice "No host motd"
