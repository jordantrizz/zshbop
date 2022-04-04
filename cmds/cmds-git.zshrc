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

# - gc
help_git[gcp]='Git commit + push'
gc () {
        git commit -am "$*" &&  git push
}

# - gbdc
help_git[gbdc]='git branch diff on commits'
gbdc () {
	if [[ ! -n $1 ]] || [[ ! -n $2 ]]; then
		echo "Usage: gbdc <branch> <branch>"
	else
		git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative $1..$2
	fi
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

