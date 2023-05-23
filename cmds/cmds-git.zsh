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
help_git[gc]='Git commit + push'
function gc () {
	_cexists glint
	if [[ $? == "0" ]]; then
		_loading "Committing using glint"
        echo "build: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
ci: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)
docs: Documentation only changes
feat: A new feature
fix: A bug fix
perf: A code change that improves performance
refactor: A code change that neither fixes a bug nor adds a feature
style: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
test: Adding missing tests or correcting existing tests
"
		glint commit
		git push
	else
		_loading "Committing using git, consider glit (software glint)"
        git commit -am "$*"
        git push
    fi
}

# - gbdc
help_git[gbdc]='git branch diff on commits'
function gbdc () {
	if [[ ! -n $1 ]] || [[ ! -n $2 ]]; then
		echo "Usage: gbdc <branch> <branch>"
	else
		git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative $1..$2
	fi
}

# -- git-config
help_git[git-config]='Configure git name and email'
function git-config () {
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

# -- gbd - Git branch delete
help_git[gbd]="Delete local and remote branch"
function gbd {
    if [[ $# -ne 1 ]]; then
        echo "Usage: git-delete-branch branch"
        return 1
    fi

    _loading "Deleting branch $1"
    git branch -D $1
    git push origin --delete $1
}

# -- gbl
help_git[gbl]="Git branch list"
function gbl {
    _loading "Listing local branches"
    git branch
    echo ""
    _loading "Listing remote branches"
    git branch -a
}

# -- gtp - Git tag push
help_git[gtp]="Git tag push"
function gtp {
    _loading "Pushing tags to origin"
    git push origin --tags
}

# -- gpab - Git pull all branches
help_git[gpab]="Git pull all branches"
function gpab {
    _loading "Pulling all branches"
    git fetch --all
    for branch in $(git branch -a | grep -v HEAD); do
        git branch --track ${branch##*/} $branch
    done
    git pull --all
}

# -- gpuab - Git push all branches
help_git[gpuab]="Git push all branches"
function gpuab {
    _loading "Pushing all branches"
    git push --all -u
}

# -- gpm - Git patch multiple
help_git[gpm]="Git patch multiple"
function gpm {
    if [[ $# -ne 1 ]]; then
        echo "Usage: git-patch-multiple commit"
        return 1
    fi

    _loading "Creating patch for commit $1 and outputting to multi_commit.patch"
    git format-patch -1 $1 --stdout > multi_commit.patch
    _loading "Creating patch for commit $1 and outputting to multi_commit.patch"
    git format-patch -1 $1 --stdout > multi_commit.patch
}

# -- gpa - Git patch apply
help_git[gpa]="Git patch apply"
function gpa {
    if [[ $# -ne 1 ]]; then
        echo "Usage: git-patch-apply patch"
        return 1
    fi

    _loading "Applying patch $1"
    git apply $1
}

# -- gl - Git log
help_git[gl]="Git log"
function gl {
    git log
}