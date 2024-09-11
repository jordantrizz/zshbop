# ------------
# Common OS functions and Aliases
# ------------

# -- Variables
AUTO_LS_CHPWD="false" # -- dont list on directory change
DEFAULT_LS="ls -al --color=tty"
alias ls="${DEFAULT_LS}"

# -- aliases
alias less="less -X"

# -- os-binary
os-binary "glow"
os-binary "fastfetch"
os-binary "glint"
os-binary "plik"

# -- sysfetch
function sysfetch () {
    DEFAULT_SYSFETCH="neofetch"
    export FASTFETCH_CONFIG="--structure Title:OS:Host:Kernel:Uptime:Packages:CPU:GPU:Memory:Disk:Shell:Terminal:TerminalFont:Locale --logo none"
    
    # -- Check if fastfetch is installed
    _debugf "Checking if fastfetch is installed"
    os-binary fastfetch
     
    if [[ $? == "1" ]]; then
        # https://superuser.com/a/1570726
        _debugf "fastfetch not found, using ${DEFAULT_SYSFETCH}"
        eval ${DEFAULT_SYSFETCH}
    else
        # -- fastfetch is installed
        _debugf "fastfetch succcess using for sysfetch and ${FASTFETCH_CONFIG}"
        #fastfetch --structure Title:OS:Host --logo none | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" | sed "s/\n/ - /g"
        #fastfetch --structure Kernel:Uptime --logo none | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g"
        _loading3 "$(fastfetch --structure Title:OS:Host --logo none | tr '\n' ' ')"
        _loading3 "$(fastfetch --structure Kernel:Uptime --logo none | tr '\n' ' ')"
        
        #eval "${FASTFETCH_CMD} ${FASTFETCH_CONFIG}"
    fi
}

# -- sysfetch-motd
function sysfetch-motd () {
    sysfetch
}

# -- tran - https://github.com/abdfnx/tran/releases
alias tran="tran_linux_amd64"

# -- check if nala is installed
check_nala () {
    _debugf_all
    _debugf "Checking if nala is installed"
    _cmd_exists nala
    if [[ $? == "0" ]]; then
        _debugf "nala installed - running zsh completions"
        source /usr/share/bash-completion/completions/nala
    fi
}

# ----------------------------------------
# -- _joe_ftyperc - setting up .joe folder @ISSUE needs to be moved
# ----------------------------------------
_joe_ftyperc () {
    _debug_all
    _log "Setting up joe ftyperc"
    if [[ -w $HOME ]]; then
        _debug "Checking for $HOME/.joe folder"
        [[ ! -d $HOME/.joe ]] && mkdir $HOME/.joe
        
        _debug "Checking for joe ftyperc in $HOME/"
        if [[ ! -f ~/.joe/ftyperc ]]; then
            _debug "Missing $HOME/.joe/ftyperc, copying"
            cp $ZSHBOP_ROOT/custom/ftyperc ~/.joe/ftyperc
        fi
    else
        _error "Can't setup \$HOME/.joe unable to write to $HOME"
        return 1
    fi

}


# =========================================================
# -- grepcidr3
# =========================================================
help_int[grepcidr3]='grepcidr3'
function _check_grepcidr3 () {
    if [[ $MACHINE_OS == "linux" ]]; then
        alias grepcidr3="grepcidr3_linux"
    fi

    if [[ $MACHINE_OS == "mac" ]]; then
        if ! _cmd_exists grepcidr3; then
            function grepcidr3 () { _error "grepcidr3 not installed, install using mac ports"; }
            return 1
        fi
    fi
}
_check_grepcidr3

# ===============================================
# -- _detect_ls
# ===============================================
DEFAULT_EXA="${EXA_CMD} --long --all --group"
function _detect_ls () {
    local LS_CMD="ls"
    
    # First check if we have eza
    _debugf "Checking for eza"
    os-binary eza
    if [[ $? == "0" ]]; then
        _debug "eza success, checking if it runs"
        EZA_RETURN=$(eza -al)
        if [[ $? -gt "0" ]]; then
            _debugf "eza failed, skipping"
        else
            _debugf "eza success, using eza for ls alias"
            alias ls="eza -al"
            return 0
        fi
    fi

    # Next check if we have exa
    _debugf "Checking for exa"
    os-binary exa
    if [[ $? == "0" ]]; then
        _debugf "exa success, using exa for ls alias"    
        EXA_RETURN=$(exa -al)
        if [[ $? -gt "0" ]]; then
            _debugf "exa failed, skipping"
        else
            _debugf "exa success, using exa for ls alias"
            alias ls="exa -al"
            return 0
        fi
    else
        _debugf "exa failed, skipping"
    fi

    # Default to ls
    _debugf "Defaulting to ls"
    alias ls="${DEFAULT_LS}"    
}
_detect_ls