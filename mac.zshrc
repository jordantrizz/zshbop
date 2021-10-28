# Mac PATH
# - Mac Ports in /opt/local/bin
export PATH=$PATH:/opt/local/bin:/opt/local/sbin/
export PATH=$PATH:/usr/local/sbin

# Mac Aliases
alias ps="/bin/ps aux"
alias ls="ls -alG"

# Mac specific commands
alias flush-dns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias eject-all="osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'"

# Brew Install
# wget mtr