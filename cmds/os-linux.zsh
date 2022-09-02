# Aliases

# -- ls/exa
unset LC_CHECK NULL
EXA_LINUX="exa-linux_x86_64"
_cexists ${EXA_LINUX}
if [[ $? == "0" ]]; then
    NULL=$(exa-linux_x86_64 2>&1 >> /dev/null)
	LC_CHECK="$?"
    _debug "exa run - out: $NULL \$?:$LC_CHECK"
	if [[ $LC_CHECK -ge "1" ]]; then
		_loading "exa failed, using default ls alias"
	else
		_loading2 "Using exa"
		alias ls="${EXA_LINUX} ${DEFAULT_EXA}"
		alias exa="${EXA_LINUX}"
	fi		
fi

# -- sys_fetch
unset LC_CHECK NULL
FF_LINUX="fastfetch-linux_x86_64"
_cexists ${FF_LINUX}
if [[ $? -ge "1" ]]; then
    alias sysfetch="neofetch"
else
    NULL=$(${FF_LINUX} 2>&1 >> /dev/null)
    LC_CHECK="$?"
    _debug "${FF_LINUX} run - out: $NULL \$?:$LC_CHECK"
    if [[ $LC_CHECK -ge "1" ]]; then
		_loading2 "Loading default neofetch"	
	else
    	_loading2 "Using fastfetch"
    	DEFAULT_SYSFETCH="$FF_LINUX"
        alias fastfetch="$FF_LINUX"
    fi
fi

# -- ps
alias ps="ps -auxwwf"

# -- tran - https://github.com/abdfnx/tran/releases
alias tran="tran_linux_amd64"

# -- macchina
alias macchine="macchina-linux-x86_64"
alias os="macchine"
