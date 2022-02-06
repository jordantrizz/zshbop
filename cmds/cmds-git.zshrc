# --
# Git commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[git]='Git related commands'

# - Init help array
typeset -gA help_git

# - gcp
help_git[gcp]='Git commit + push'
gcp () {
        git commit -am "$*" &&  git push
}

# -- git-config
help_git[git-config]='Configure git name and email'
git-config () {
        vared -p "Name? " -c GIT_NAME
        vared -p "Email? " -c GIT_EMAIL
        git config --global user.email $GIT_EMAIL
        git config --global user.name $GIT_NAME
        git config --global --get user.email
        git config --global --get user.name
}

