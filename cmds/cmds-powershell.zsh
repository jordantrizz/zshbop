# --
# powershell commands
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[powershell]="Microsoft Powershell commands"

# - Init help array
typeset -gA help_powershell

_debug " -- Loading ${(%):-%N}"

# ===============================================
# -- powershell-check
# ===============================================
help_powershell[powershell-check]='Check if Powershell is installed.'
powershell-check () {
    local QUIET=${1:-0}
    _cmd_exists pwsh
    if [[ $? -eq 0 ]]; then
        [[ $QUIET -eq 0 ]] && echo "Powershell is installed."
        return 0
    else
        [[ $QUIET -eq 0 ]] && echo "Powershell is not installed."
        return 1
    fi
}

# ===============================================
# -- powershell-install-exo
# ===============================================
help_powershell[powershell-install-exo]='Install Exchange Online module.'
powershell-install-exo () {
    powershell-check 1
    [[ $? -ne 0 ]] && { echo "Powershell is not installed."; return 1; }
    pwsh -c "Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber"
}