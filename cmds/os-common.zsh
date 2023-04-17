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
sysfetch () {
    DEFAULT_SYSFETCH="neofetch"
    os-binary fastfetch
    _debug "Checking if fastfetch is installed"
    if [[ $? == "1" ]]; then
        _debug "fastfetch not found, using ${DEFAULT_SYSFETCH}"
        eval ${DEFAULT_SYSFETCH}
    else
        _debug "fastfetch succcess using for sysfetch"
        eval fastfetch
    fi
}

# -- ls/exa
os-binary "exa"

# -- glow
os-binary "glow"


# -- tran - https://github.com/abdfnx/tran/releases
alias tran="tran_linux_amd64"

# -- check if nala is installed
check_nala () {
        _debug_function
        _debug "Checking if nala is installed"
        _cexists nala
        if [[ $? == "0" ]]; then
            _debug "nala installed - running zsh completions"
            source /usr/share/bash-completion/completions/nala
        fi
}

# ----------------------------------------
# -- _joe_ftyperc - setting up .joe folder @ISSUE needs to be moved
# ----------------------------------------
_joe_ftyperc () {
    _debug_function
    _debug "Checking for ~/.joe folder"
    [[ ! -d ~/.joe ]] && mkdir ~/.joe
    
    _debug "Checking for joe ftyperc"
    if [[ ! -f ~/.joe/ftyperc ]]; then
    	_debug "Missing ~/.joe/ftyperc, copying"
        cp $ZSHBOP_ROOT/custom/ftyperc ~/.joe/ftyperc
    fi
}
