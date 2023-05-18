# --
# Example help: help_zsh[zsh]='Rung zsh'
#
# --

# What help file is this?
help_files[zsh]='ZSH related commands'

# - Init help array
typeset -gA help_zsh

# -- zsh-bin
help_zsh[zsh-bin]='Install zsh-bin from https://github.com/romkatv/zsh-bin'
function zsh-bin() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)"
}