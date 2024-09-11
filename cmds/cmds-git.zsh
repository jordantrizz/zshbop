# =============================================================================
# -- Git commands
# =============================================================================
_debug " -- Loading ${(%):-%N}"
help_files[git]='Git related commands'
typeset -gA help_git

# =====================================
# -- gc
# =====================================
help_git[gc]='Git commit + push'
function _gc_replace (){
    if _cmd_exists gc; then
        # Check if gc is an alias
        if [[ $(type gc) == "gc is an alias for git commit --verbose" ]]; then
            _log "gc is an omz alias, removing"
            unalias gc
        fi
    fi
    function gc () {
        _loading "Committing using git, consider using glc"
        git add *
        git commit -am "$*"
        git push
    }    
}
INIT_LAST_CORE+=("_gc_replace")

# =====================================
# -- glc
# =====================================
help_git[glc]='Glint commit and push'
function glc () {
	_cmd_exists glint
	if _cmd_exists glint; then
        _loading "Committing using glint"
		glint commit
		git push
	else
		_error  "Glint not installed use software glint to install"
    fi
}

# =====================================
# - gbdc
# =====================================
help_git[gbdc]='git branch diff on commits'
function gbdc () {
    log_lines=${3:-5}
	if [[ ! -n $1 ]] || [[ ! -n $2 ]]; then
		echo "Usage: gbdc <branch> <branch> [log-lines]"
	else
		git log -n $log_lines --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative $1..$2
	fi
}

# =====================================
# -- git-config
# =====================================
help_git[git-config]='Configure git name and email'
function git-config () {
        vared -p "Name? " -c GIT_NAME
        vared -p "Email? " -c GIT_EMAIL
        git config --global user.email $GIT_EMAIL
        git config --global user.name $GIT_NAME
        git config --global --get user.email
        git config --global --get user.name
}

# =====================================
# -- grb
# =====================================
help_git[grb]='List git remote branches'
function grb {
    git -P branch -r
}

# =====================================
# -- grp
# =====================================
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
    local BRANCH1=$1 BRANCH2=$2 LINES=${3:-15}
    if [[ $# -ne 2 ]]; then
        echo "Usage: git-compare-branches <branch1> <branch2> [lines]"
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
        git log --pretty=format:"%h - %s (%ad)" --date=short "$1" | head -15
        echo ""
        echo ""
        _loading2 "Last 5 commits from $2:"
        git log --pretty=format:"%h - %s (%ad)" --date=short "$2" | head -15
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

# ===============================================
# -- gbl
# ===============================================
help_git[gbl]="Git branch list"
function _gbl_replace {
    if _cmd_exists gbl; then
        # Check if gc is an alias
        if [[ $(type gbl) == "gbl is an alias for git blame -w" ]]; then
            _log "gbl is an omz alias, removing"
            unalias gbl
        fi
    fi
    function gbl () {
        _loading "Listing local and remote branches"
        git --no-pager branch -a
    }
}
INIT_LAST_CORE+=("_gbl_replace")

# =====================================
# -- gtpush - Git tag push
# =====================================
help_git[gtpush]="Git tag push"
function gtpush {
    _loading "Pushing tags to origin"
    git push origin --tags
}

# =====================================
# -- gtdelete - Git tag delete
# =====================================
help_git[gtdelete]="Delete local and remote tag"
function gtdelete {
    if [[ $# -ne 1 ]]; then
        echo "Usage: git-delete-tag tag"
        return 1
    fi

    _loading "Deleting tag $1"
    git tag -d $1
    git push origin :refs/tags/$1
}

# =====================================
# -- gpab - Git pull all branches
# =====================================
help_git[gpab]="Git pull all branches"
function gpab {
    _loading "Pulling all branches"
    git fetch --all
    for branch in $(git branch -a | grep -v HEAD); do
        git branch --track ${branch##*/} $branch
    done
    git pull --all
}

# =====================================
# -- gpuab - Git push all branches
# =====================================
help_git[gpuab]="Git push all branches"
function gpuab {
    _loading "Pushing all branches"
    git push --all -u
}

# =====================================
# -- gpm - Git patch multiple
# =====================================
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

# =====================================
# -- gpa - Git patch apply
# =====================================
help_git[gpa]="Git patch apply"
function gpa {
    if [[ $# -ne 1 ]]; then
        echo "Usage: git-patch-apply patch"
        return 1
    fi

    _loading "Applying patch $1"
    git apply $1
}

# =====================================
# -- grr - Git reset remote
# =====================================
help_git[grr]="Git reset remote"
function grr {
    if [[ $# -ne 1 ]]; then
        echo "Usage: git-reset-remote branch"
        return 1
    fi

    _loading "Resetting remote branch $1"
    git reset --hard origin/$1
}

# =====================================
# -- gl - Git log
# =====================================
help_git[gl]="Git log"
function gl {
    git log
}

# =====================================
# -- git-check
# =====================================
help_git[git-check]="Check for uncommitted changes and unpushed commits in all Git repositories"
function git-check () {
    local GIT_DIR
    if [[ $1 == "-h" ]]; then
        echo "Usage: git-check <directory>"
    elif [[ -n $1 ]]; then
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

# =====================================
# -- git-check-repos
# =====================================
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
        local AHEAD="$(git -C "$DIR" rev-list --count --right-only @{u}...HEAD)"
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

# =====================================
# -- git-repos-updates
# =====================================
help_git[git-repos-updates]="Check for updates in all Git repositories"
function git-repos-updates () {
    # -- git-repos-updates_do $GIT_PATH
    _git-repos_updates_do () {
        local GIT_PATH="$1" FOUND_GIT_DIRS=()
        FOUND_GIT_DIRS=($(find "$GIT_PATH" -name ".git" -type d -prune ))
        for DIR in ${FOUND_GIT_DIRS[@]}; do
            # Check for unpushed commits
            local AHEAD="$(git -C "$DIR" rev-list --count --left-only @{u}...HEAD)"
            if [[ "$AHEAD" -gt 0 ]]; then
                UNPUSHED_CODE=1
                echo "   - New Commits: $AHEAD - ${bg[magenta]}$DIR${RSC}"
            fi
        done

        if [[ -n $UNCOMMITED_CODE || -n $UNPUSHED_CODE ]]; then
            _warning "Uncommitted or unpushed code found"
            return 1
        fi
    }

    local GIT_DIR=${1}

    # -- Pick a directory to check
    if [[ -n $GIT_DIR ]]; then
        _loading "Using \$1 as \$GIT_HOME: $1"
        GIT_DIR="$1"
        [[ -d $1 ]] || { _error "$1 is not a directory"; return 1; }
        _git-repos_updates_do "$GIT_DIR"
    elif [[ -n $GIT_HOME ]]; then
        _loading "Found and using \$GIT_HOME: $GIT_HOME"
        GIT_DIR="$GIT_HOME"
        [[ -d $GIT_HOME ]] || { _error "$GIT_HOME is not a directory"; return 1; }
        _git-repos_updates_do "$GIT_DIR"
    else
        echo "Usage: git-repos-updates <directory>"
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

# =====================================
# -- git-squash-commits
# =====================================
help_git[git-squash-commits]="Squash commits"
function git-squash-commits () {
    GIT_LOG="$(git log --oneline)"
    git reset $(git commit-tree HEAD^{tree} -m "$GIT_LOG")
}

# =====================================
# -- gtpull - Git tag pull
# =====================================
help_git[gtpull]="Pull tags from remote"
function gtpull {
    _loading "Pulling tags from remote"
    git fetch --tags
}

# =====================================
# -- gtlist - Git tag list local and remote
# =====================================
help_git[gtlist]="List tags"
function gtlist {
    _loading "Listing tags"
    git -P tag -l
    _loading "Listing remote tags"
    git ls-remote --tags
}

# =====================================
# -- gcapf - Git commit ammend push force
# =====================================
help_git[gcapf]="Commit ammend push force"
function gcapf {
    _loading "Commit ammending"
    git commit --amend --no-edit -a
    _loading "Pushing force"
    git push --force
}

# =====================================
# -- gprh - Git pull reset hard origin current branch
# =====================================
help_git[gprh]="Pull reset hard origin current branch"
function gprh {
    _loading "Pulling"
    git pull
    _loading "Resetting hard"
    git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)
}

# ==============================================================================
# -- gcldupe - Git commit log remove duplicates
# ==============================================================================
help_git[gcldupe]="Remove duplicate commits from git log"
function gcldupe () {
    local GIT_COMMIT="$1"
    # Remove first column
    _usage_gcldupe () {
        echo "Usage: gcldupe <last-commit>"
    }

    [[ -z $GIT_COMMIT ]] && { _usage_gcldupe; return 1; }

    GIT_LOG="$(git log $GIT_COMMIT..HEAD --oneline | awk '{$1=""; sub(/^ /, ""); print $0}' | sort -u)"
    
    echo "$GIT_LOG"
}

# =====================================
# -- git-ssh-key
# =====================================
help_git[git-ssh-key]="Generate SSH key for git to be used for github code deploy"
function git-ssh-key () {
    local CURRENT_DIR_NAME=$(basename $(pwd))
    local GIT_KEY_PATH="$HOME/.ssh/${CURRENT_DIR_NAME}_git"
    local CREATE=$1
    [[ -z $CREATE ]] && {
        echo "Usage: git-ssh-key [create]"
        echo "  Generate an ssh-key for a git repo to be used for github code deploy"
        return 1
    }

    # -- Check if current dir is a git repo
    if [[ ! -d .git ]]; then
        _error "Not a git repo"
        return 1
    fi

    # -- Check if ssh-key already exists
    if [[ -f "$GIT_KEY_PATH" ]]; then
        _error "SSH key already exists: $GIT_KEY_PATH"
        return 1
    fi

    # -- Create ssh-key ed25519
    _loading "Creating ssh-key: $GIT_KEY_PATH"
    ssh-keygen -t ed25519 -f $GIT_KEY_PATH -C "$CURRENT_DIR_NAME" -N ""

    # -- Add ssh-key to git repo for pushing
    _loading "Adding ssh-key to git repo"
    git config core.sshCommand "ssh -i $GIT_KEY_PATH -F /dev/null"

    _success "Compelted"
    cat $GIT_KEY_PATH.pub
}

# =====================================
# -- git-config-defaults
# =====================================
help_git[git-config-defaults]="Set git config defaults."
function git-config-defaults () {
    local GIT_LOAD_DEFAULTS="0"
    _loading "Setting git config defaults for current repository"

    # -- Confirm if git is installed
    if ! _cmd_exists git; then
        _error "Git is not installed"
        return 1
    fi
    # -- Check if current dir is a git repo
    if [[ ! -d .git ]]; then
        _error "Not a git repo"
        return 1
    fi
    
    # Check for git defaults file.
    if [[ -f "$HOME/.gitconfig.defaults" ]]; then
        _loading2 "Found git defaults file: $HOME/.gitconfig.defaults"
        GIT_LOAD_DEFAULTS="1"
    else
        _warning "Couldn't find git defaults file, using common defaults"
    fi

    if [[ -f "$ZBC_HOME/.gitconfig.defaults" ]]; then
        _loading2 "Found git defaults file: $ZBC_HOME/.gitconfig.defaults"
        GIT_LOAD_DEFAULTS="1"    
    else
        _warning "Couldn't find git defaults file, using common defaults"
    fi
    
    if [[ $GIT_LOAD_DEFAULTS == "0" ]]; then
        _loading2 "Couldn't find git defaults file, applying common defaults"
        _loading3 "Setting git merge to fast forward only"
        git config --global merge.ff only
        _loading3 "Setting git pull to rebase"
        git config --global pull.rebase true
    fi
}

# =====================================
# -- git-release
# =====================================
help_git[git-release]="Create a GitHub release using the latest tag and commit message"
git-release() {
  # grab the most recent tag
  local tag
  tag=$(git describe --tags --abbrev=0) || {
    echo "❌ no tags found"; return 1
  }

  # grab the latest commit message
  local msg
  msg=$(git log -1 --pretty=%B)

  # run GH CLI release create with tag, using the tag as title and the commit msg as notes
  gh release create "$tag" \
    --title "$tag" \
    --notes "$msg"
}

# =====================================
# -- git-amend-clean
# =====================================
help_git[git-amend-clean]="Remove empty links and duplicates from the last commit message"
git-amend-clean() {
  # Grab the last commit message
  local raw_msg
  raw_msg="$(git log -1 --pretty=%B)"

  # Clean it: trim leading/trailing whitespace, remove empty lines, drop duplicates
  local cleaned_msg
  cleaned_msg="$(printf '%s\n' "$raw_msg" \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
    | awk '!seen[$0]++ && NF' \
    | paste -sd '\n' -)"

  # Amend the commit with the cleaned message
  git commit --amend -m "$cleaned_msg"
}
