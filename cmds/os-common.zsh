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

# -- check_diskspace_linux
check_diskspace_linux () {
    ALERT="98" # alert level
    # :\\ = wsl drive letters
    # /run = not requires
    # wsl = wsl stuffs
    # /init = wsl stuffs
    DF_COMMAND=$(df -H 2>/dev/null | grep -vE '^Filesystem|tmpfs|cdrom|:\\|wsl|/run|/init|overlay|none|/dev/loop*|devfs' | awk '{ print $5 " " $1 }' )
    #IFS=$'\n' read -rd '' DISKUSAGE <<< "$DF_COMMAND"
    DISKUSAGE=("${(@f)${DF_COMMAND}}")
    for OUT in ${DISKUSAGE[@]}; do
        PERCENTAGE=$(echo "$OUT" | awk '{ print $1}' | cut -d'%' -f1 )
        PARTITION=$(echo "$OUT" | awk '{ print $2 }' )
        FIRSTMSG="Checking $PARTITION with $PERCENTAGE%"

        # - Check percentage and then alert.
        if [[ $PERCENTAGE -ge $ALERT ]]; then
            _notice "$FIRSTMSG.."
            _error "Space issue on ${PARTITION} (${PERCENTAGE}%)"
        else
            _notice "$FIRSTMSG.. - no issue."
        fi
    done
}}