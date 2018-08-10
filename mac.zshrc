# Mac Aliases
alias ps="/bin/ps aux"
alias ls="ls -alG"

# Mac specific commands
alias flush-dns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias eject-all="osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'"
