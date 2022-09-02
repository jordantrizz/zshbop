# Mac PATH
# - Mac Ports in /opt/local/bin
export PATH=$PATH:/opt/local/bin:/opt/local/sbin/
export PATH=$PATH:/usr/local/sbin

# -- ls/exa
unset LC_CHECK NULL
EXA_MAC="exa-macos_x86_64"
_cexists $EXA_MAC
if [[ $? == "0" ]]; then
    NULL=$(${EXA_MAC} 2>&1 >> /dev/null)
    LC_CHECK="$?"
    _debug "exa run - out: $NULL \$?:$LC_CHECK"
    if [[ $LC_CHECK -ge "1" ]]; then
        _debug "exa failed, using default ls alias"
        alias ls="$DEFAUKLT_LS"
    else
    	_debug "exa success, using exa for ls alias"
    	alias ls="${EXA_MAC}${DEFAULT_EXA}"
    fi
fi

# -- sys_fetch
unset LC_CHECK NULL
DEFAULT_SYSFETCH="neofetch"
FF="fastfetch-macos_x86_64"
_cexists ${FF} > /dev/null
if [[ $? == "1" ]]; then
	_debug "${FF} not found, using ${DEFAULT_SYSFETCH}"
    sysfetch () { ${DEFAULT_SYSFETCH} }
else
    NULL=$(${FF} 2>&1 >> /dev/null)
    LC_CHECK="$?"
    _debug "${FF} run - out: $NULL \$?:$LC_CHECK"
    if [[ $LC_CHECK -ge "1" ]]; then
    	_debug "fastfetch failed, using ${DEFAULT_SYSFETCH}"
        sysfetch () { neofetch }
    else
		_debug "fastfetch succcess, using ${FF} for sysfetch"
    	alias="${FF}"
    fi
fi

# -- ps
alias ps="/bin/ps aux"

# Mac specific commands
alias flush-dns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias eject-all="osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'"

# Brew Install
# wget mtr