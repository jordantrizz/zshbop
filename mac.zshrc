# Mac PATH
# - Mac Ports in /opt/local/bin
export PATH=/opt/local/bin:/opt/local/sbin/:$PATH
export PATH=/usr/local/sbin:$PATH

# Mac Aliases
alias ps="/bin/ps aux"
alias ls="ls -alG"

# Mac specific commands
alias flush-dns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias eject-all="osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'"

# Brew Install
# wget mtr