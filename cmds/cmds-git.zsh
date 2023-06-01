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

# -- gtpush - Git tag push
help_git[gtpush]="Git tag push"
function gtpush {
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

# -- grr - Git reset remote
help_git[grr]="Git reset remote"
function grr {
    if [[ $# -ne 1 ]]; then
        echo "Usage: git-reset-remote branch"
        return 1
    fi

    _loading "Resetting remote branch $1"
    git reset --hard origin/$1
}

# -- gl - Git log
help_git[gl]="Git log"
function gl {
    git log
}

# -- git-check
help_git[git-check]="Check for uncommitted changes and unpushed commits in all Git repositories"
function git-check () {
    local GIT_DIR
    if [[ -n $1 ]]; then
        _loading "Using \$1 as \$GIT_HOME: $1"
        GIT_DIR="$1"
        [[ -d $1 ]] || { _error "$1 is not a directory"; return 1; }
        git-check-repos "$GIT_DIR"
    elif [[ -n $GIT_HOME ]]; then
        _loading "Found and using \$GIT_HOME: $GIT_HOME"
        GIT_DIR="$GIT_HOME"
        [[ -d $GIT_HOME ]] || { _error "$GIT_HOME is not a directory"; return 1; }
        git-check-repos "$GIT_DIR"
    else
        echo "Usage: git-check <directory>"
    fi
}

# -- git-check-repos
function git-check-repos () {
    local UNCOMMITED_CODE UNPUSHED_CODE
    if [[ -z $1 ]];then
        return 1
    else
        GIT_DIR="$1"
    fi

    # Find all directories containing a Git repository
    FOUND_GIT_DIRS=($(find "$GIT_DIR" -name ".git" -type d -prune ))

    # Iterate over the Git repositories
    for DIR in ${FOUND_GIT_DIRS[@]}; do
        DIR=$(dirname $DIR)
        _debug "Checking $DIR"

        # Check for uncommitted changes and untracked files
        DIR_STATUS_CMD="$(git -C "$DIR/.git" --work-tree="$DIR" status --porcelain)"
        DIR_STATUS_ARRAY=("${(f)DIR_STATUS_CMD}")
        if [[ -n $DIR_STATUS_CMD ]]; then
            UNCOMMITED_CODE=1
            echo "   - Uncommited: ${bg[magenta]}${DIR}${RSC}"
            for FILE in ${DIR_STATUS_ARRAY[@]} ; do
                echo "      -- $FILE"
            done
        fi

        # Check for unpushed commits
        local AHEAD="$(git -C "$DIR" rev-list --count --left-only @{u}...HEAD)"
        if [[ "$AHEAD" -gt 0 ]]; then
            UNPUSHED_CODE=1
            echo "   - Commits: $AHEAD - ${bg[magenta]}$DIR${RSC}"
        fi
    done

    if [[ -n $UNCOMMITED_CODE || -n $UNPUSHED_CODE ]]; then
        _warning "Uncommitted or unpushed code found"
        return 1
    fi
}

# -- git-check-exit
help_git[git-check-exit]="Check for uncommitted changes and unpushed commits in all Git repositories and exit with error code if any are found"
function git-check-exit () {
    [[ ! -d $GIT_HOME ]] && return 0
    git-check-repos $GIT_HOME
    if [[ $? -ne 0 ]]; then
        echo -n "Uncommited and unpushed changes found. Press enter to continue anyway or 'r' to return to ZSH\n"
        read response
        if [[ $response != "" ]]; then
            zsh
        else
            exit 1
        fi
    fi
}

# -- git-squash-commits
help_git[git-squash-commits]="Squash commits"
function git-squash-commits () {
    GIT_LOG="$(git log --oneline)"
    git reset $(git commit-tree HEAD^{tree} -m "$GIT_LOG")
}

# -- gtd - Git tag delete
help_git[gtd]="Delete local and remote tag"
function gtd {
    if [[ $# -ne 1 ]]; then
        echo "Usage: git-delete-tag tag"
        return 1
    fi

    _loading "Deleting tag $1"
    git tag -d $1
    git push origin :refs/tags/$1
}

# -- gtpull - Git tag pull
help_git[gtpull]="Pull tags from remote"
function gtpull {
    _loading "Pulling tags from remote"
    git fetch --tags
}

# -- gtlist - Git tag list local and remote
help_git[gtlist]="List tags"
function gtlist {
    _loading "Listing tags"
    git -P tag -l
    _loading "Listing remote tags"
    git ls-remote --tags
}

# -- gcapf - Git commit ammend push force
help_git[gcapf]="Commit ammend push force"
function gcapf {
    _loading "Commit ammending"
    git commit --amend --no-edit -a
    _loading "Pushing force"
    git push --force
}

# -- gprh - Git pull reset hard origin current branch
help_git[gprh]="Pull reset hard origin current branch"
function gprh {
    _loading "Pulling"
    git pull
    _loading "Resetting hard"
    git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)
}