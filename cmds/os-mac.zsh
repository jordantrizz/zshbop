# Mac PATH
# - Mac Ports in /opt/local/bin
export PATH=$PATH:/opt/local/bin:/opt/local/sbin/
export PATH=$PATH:/usr/local/sbin

# -- auto-ls zsh plugin - needs to be defined in order
DEFAULT_LS="ls -Gal"
alias ls="$DEFAULT_LS"

# -- Variables

# -- aliases
alias ps="/bin/ps aux"
alias flush-dns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias eject-all="osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'"

# -- ls/exa
_cexists exa
if [[ $? -ge "1" ]]; then
	_debug "exa failed, using default ls alias"
    alias ls="${DEFAULT_LS}"
else
    _debug "exa success, using exa for ls alias"
    alias ls="exa -al"
fi

# -- autols
auto-ls-ls () {
	\ls -a
	echo ""
}