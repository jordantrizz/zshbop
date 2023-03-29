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
		git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative $1..$2
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

# -- grb
help_git[grb]='List git remote branches'
function grb {
    git -P branch -r
}

# -- grp
help_git[grp]='Pull down remote branches'
function grp {
    git fetch --all
    for branch in $(git branch -r | grep -v HEAD); do
        git branch --track ${branch##*/} $branch
    done
    git pull --all
}

# -- gcb
help_git[gcb]='Compare two branches'
function gcb {
    if [[ $# -ne 2 ]]; then
        echo "Usage: git-compare-branches branch1 branch2"
        return 1
    fi

    _loading "Comparing $1 with $2"
    echo ""

    git fetch
    branch1_commit=$(git rev-parse --short=7 "$1")
    branch2_commit=$(git rev-parse --short=7 "$2")
    if [[ "$branch1_commit" == "$branch2_commit" ]]; then
        echo "Both branches are at the same commit: $branch1_commit"
    else
        _loading2 "Last 5 commits from $1:"
        git log --pretty=format:"%h - %s (%ad)" --date=short "$1" | head -5
        echo ""
        _loading2 "Last 5 commits from $2:"
        git log --pretty=format:"%h - %s (%ad)" --date=short "$2" | head -5
    fi
}

# -- gcab
help_git[gcab]='Compare all branches'
function gcab {
    if [[ $# -eq 2 ]]; then
        _loading "Comparing $1 with $2"
        echo ""
        git fetch
        branch1_commit=$(git rev-parse --short=7 "$1")
        branch2_commit=$(git rev-parse --short=7 "$2")
        if [[ "$branch1_commit" == "$branch2_commit" ]]; then
            echo "Both branches are at the same commit: $branch1_commit"
        else
            _loading2 "Last 5 commits from $1:"
            git log --pretty=format:"%h - %s (%ad)" --date=short "$1" | head -5
            echo ""
            _loading2 "Last 5 commits from $2:"
            git log --pretty=format:"%h - %s (%ad)" --date=short "$2" | head -5
        fi
    else
        _loading "Fetching all remote branches..."
        git fetch --all
        _loading2 "Comparing all branches..."
        for branch in $(git branch -a | grep -v HEAD); do
            if [[ $branch != *remotes/origin/HEAD* ]]; then
                branch_commit=$(git rev-parse --short=7 "$branch")
                echo ""
                _loading3 "Branch $branch_commit: $branch"
                _loading4 "Last 5 commits:"
                git log --pretty=format:"%h - %s (%ad)" --date=short "$branch" | head -5
            fi
        done
    fi
}



