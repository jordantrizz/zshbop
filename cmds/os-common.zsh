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

# -- os-binary
os-binary "fastfetch"
os-binary "exa"
os-binary "glow"
os-binary "glint"

# -- sysfetch
function sysfetch () {
    DEFAULT_SYSFETCH="neofetch"
    export FASTFETCH_CONFIG="--structure Title:OS:Host:Kernel:Uptime:Packages:CPU:GPU:Memory:Disk:Shell:Terminal:TerminalFont:Locale --logo none"
    
    # -- Check if fastfetch is installed
    _debug "Checking if fastfetch is installed"
    os-binary fastfetch 
     
    if [[ $? == "1" ]]; then
        # https://superuser.com/a/1570726
        _debug "fastfetch not found, using ${DEFAULT_SYSFETCH}"
        eval ${DEFAULT_SYSFETCH}
    else
        # -- fastfetch is installed
        _debug "fastfetch succcess using for sysfetch and ${FASTFETCH_CONFIG}"
        #fastfetch --structure Title:OS:Host --logo none | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" | sed "s/\n/ - /g"
        #fastfetch --structure Kernel:Uptime --logo none | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g"
        _loading3 "$(fastfetch --structure Title:OS:Host --logo none | tr '\n' ' ')"
        _loading3 "$(fastfetch --structure Kernel:Uptime --logo none | tr '\n' ' ')"
        
        #eval "${FASTFETCH_CMD} ${FASTFETCH_CONFIG}"
    fi
}

function sysfetch-motd () {
    sysfetch
}

# -- tran - https://github.com/abdfnx/tran/releases
alias tran="tran_linux_amd64"

# -- check if nala is installed
check_nala () {
    _debug_all
    _debug "Checking if nala is installed"
    _cmd_exists nala
    if [[ $? == "0" ]]; then
        _debug "nala installed - running zsh completions"
        source /usr/share/bash-completion/completions/nala
    fi
}

# ----------------------------------------
# -- _joe_ftyperc - setting up .joe folder @ISSUE needs to be moved
# ----------------------------------------
_joe_ftyperc () {
    _debug_all
    _loading3 "Setting up joe ftyperc"
        
    _debug "Checking for $ZSHBOP_HOME/.joe folder"
    [[ ! -d $ZSHBOP_HOME/.joe ]] && mkdir $ZSHBOP_HOME/.joe
    
    _debug "Checking for joe ftyperc in $ZSHBOP_HOME/.joe/ftyperc"
    if [[ ! -f $ZSHBOP_HOME/.joe/ftyperc ]]; then
    	_debug "Missing $ZSHBOP_HOME/.joe/ftyperc, copying"
        cp $ZSHBOP_ROOT/custom/ftyperc $ZSHBOP_HOME/.joe/ftyperc
    fi
}
