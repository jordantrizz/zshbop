# ------------
# Common OS functions and Aliases
# ------------

# -- ls/exa
DEFAULT_LS="ls -al --color=tty"
alias ls="${DEFAULT_LS}"
DEFAULT_EXA="${EXA_CMD} --long --all --group"

# -- sysfetch
DEFAULT_SYSFETCH="neofetch"
sysfetch () { 
	${DEFAULT_SYSFETCH}
}

# -- tran - https://github.com/abdfnx/tran/releases
alias tran="tran_linux_amd64"
