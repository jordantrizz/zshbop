# ------------
# Common OS functions and Aliases
# ------------

# -- Variables
AUTO_LS_CHPWD="false" # -- dont list on directory change
DEFAULT_LS="ls -al --color=tty"

# -- aliases
alias less="less -X"

# -- ls/exa
alias ls="${DEFAULT_LS}"
DEFAULT_EXA="${EXA_CMD} --long --all --group"

# -- sysfetch
DEFAULT_SYSFETCH="neofetch"

# -- sys_fetch
os-binary "fastfetch"
if [[ $? == "1" ]]; then
    _debug "fastfetch not found, using ${DEFAULT_SYSFETCH}"
    sysfetch () { ${DEFAULT_SYSFETCH} }
else
	_debug "fastfetch succcess using for sysfetch"
	sysfetch () { fastfetch }
fi

# -- sys_fetch
os-binary "exa"

# -- glow
os-binary "glow"


# -- tran - https://github.com/abdfnx/tran/releases
alias tran="tran_linux_amd64"
