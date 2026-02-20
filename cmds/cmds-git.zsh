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
# -- gc shortcuts
# =====================================
help_git[gc-todo]='Commit and push TODO.md only'
function gc-todo () {
    local COMMIT_MESSAGE="${*:-docs: Updated TODO.md}"

    if [[ ! -f TODO.md ]]; then
        _error "TODO.md not found in current directory"
        return 1
    fi

    _loading "Committing TODO.md only"
    git add TODO.md || return 1
    git commit -m "$COMMIT_MESSAGE" -- TODO.md || return 1
    git push
}

help_git[gc-agent]='Commit and push AGENTS.md only'
function gc-agent () {
    local COMMIT_MESSAGE="${*:-docs: Updated AGENTS.md}"

    if [[ ! -f AGENTS.md ]]; then
        _error "AGENTS.md not found in current directory"
        return 1
    fi

    _loading "Committing AGENTS.md only"
    git add AGENTS.md || return 1
    git commit -m "$COMMIT_MESSAGE" -- AGENTS.md || return 1
    git push
}

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

# =====================================
# -- gbdall - Git branch delete
# =====================================
help_git[gbdall]="Delete local and remote branch"
# -- Check if gbd alias exists 
function gbdall {
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
# -- gtpush - Git tag push (optionally create a tag first)
# =====================================
help_git[gtpush]="Git tag push (optionally create tag first)"
function gtpush {
    # Handle help flag
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        echo "Usage: gtpush [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -h, --help          Show this help message"
        echo ""
        echo "Commands:"
        echo "  gtpush              Push all tags to origin"
        echo "  gtpush <tag>        Create tag and push to origin (interactive if exists)"
        echo "  gtpush <tag> <ref>  Create tag on specific commit/ref and push to origin"
        echo ""
        echo "Examples:"
        echo "  gtpush 1.4.0        Create tag 1.4.0 on HEAD and push"
        echo "  gtpush 1.4.0 abc123 Create tag 1.4.0 on commit abc123 and push"
        return 0
    fi
    
    if [[ -n "$1" ]]; then
        local tag="$1"
        local ref="${2:-HEAD}"  # Default to HEAD if no ref provided
        
        # Check if tag already exists locally
        if git tag -l "$tag" | grep -q "^${tag}$"; then
            # Tag already exists - prompt user for action
            _warning "Tag '$tag' already exists"
            echo ""
            echo "Choose action:"
            echo "  (l) Delete locally only"
            echo "  (b) Delete locally and remotely"
            echo "  (n) No, exit"
            echo ""
            read -k 1 "choice?Select [l/b/n]: "
            echo ""
            
            case $choice in
                l)
                    _loading "Deleting tag $tag locally"
                    git tag -d "$tag" || { _error "Failed to delete local tag $tag"; return 1; }
                    ;;
                b)
                    _loading "Deleting tag $tag locally and remotely"
                    git tag -d "$tag" || { _error "Failed to delete local tag $tag"; return 1; }
                    git push origin --delete "$tag" 2>/dev/null || { _warning "Failed to delete remote tag $tag (may not exist)"; }
                    ;;
                n|*)
                    _error "Aborting tag creation"
                    return 1
                    ;;
            esac
        fi
        
        _loading "Creating tag $tag on $ref"
        if ! git tag "$tag" "$ref"; then
            _error "Failed to create tag $tag"
            return 1
        fi
        
        _loading "Pushing tag $tag to origin"
        if git push origin "$tag"; then
            _success "Tag $tag created and pushed"
        else
            _error "Failed to push tag $tag"
            return 1
        fi
        return 0
    else
        _loading "Pushing all tags to origin"
        git push origin --tags
    fi
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
help_git[git-check-exit]="Check for uncommitted changes and unpushed commits in all Git repositories on shell exit"
function git-check-exit () {
    # Skip if we're reloading zshbop (not actually exiting)
    # Use temp file flag since env vars may not propagate to trap context
    local reload_flag="${TMPDIR:-/tmp}/.zshbop_reload_$$"
    if [[ -f "$reload_flag" ]]; then
        rm -f "$reload_flag"
        return 0
    fi
    
    [[ ! -d $GIT_HOME ]] && return 0
    git-check-repos $GIT_HOME
    if [[ $? -ne 0 ]]; then
        echo ""
        echo -n "Uncommited and unpushed changes found. Press 'c' to cancel exit, or Enter to continue: "
        read -k 1 response
        echo ""
        if [[ $response == "c" || $response == "C" ]]; then
            # Cancel the exit by starting a new shell
            exec zsh
        fi
        # Otherwise continue with exit
    fi
}

# =====================================
# -- git-squash-commits
# =====================================
help_git[git-squash-commits]="Squash commits"
function git-squash-commits () {
    GIT_LOG="$(git log --oneline)"
    git reset $(git commit-tree 'HEAD^{tree}' -m "$GIT_LOG")
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

    git config --global alias.amend '!git add -A && git commit --amend --no-edit'
}

# =====================================
# -- git-create-release
# =====================================
help_git[gh-create-release]="Create a GitHub release for the current tag; use -a/--all to create releases for all local tags missing on GitHub"
function gh-create-release() {
    _loading "Creating GitHub release"

    # Verify GitHub CLI and repo context
    _loading2 "Checking if GitHub CLI (gh) is installed"
    if ! _cmd_exists gh; then
        _error "GitHub CLI (gh) is not installed"
        return 1
    fi

    _loading2 "Checking if in a git repository"
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        _error "Not in a git repository"
        return 1
    fi

    # Parse options with zparseopts
    local -a _args
    local -a _opt_all _opt_help
    zparseopts -D -E -a _args -- a=_opt_all -all=_opt_all h=_opt_help -help=_opt_help

    local DO_ALL
    DO_ALL=0
    if (( ${#_opt_all} )); then
        DO_ALL=1
    fi
    if (( ${#_opt_help} )); then
        echo "Usage: gh-create-release [-a|--all]"
        echo "  Default: create a GitHub release for the tag at HEAD (must be exactly tagged)"
        echo "  -a, --all   Create releases for all local tags that do not have a GitHub release"
        return 0
    fi
    # Warn about unexpected leftover args
    if (( ${#_args} )); then
        _warning "Ignoring unexpected arguments: ${_args[*]}"
    fi

    if [[ $DO_ALL -eq 1 ]]; then
        _loading2 "Bulk mode: creating releases for local tags missing on GitHub"

        # Gather local tags
        local local_tags_text
        local -a local_tags
        local_tags_text=$(git tag)
        local_tags=("${(f)local_tags_text}")
        if [[ ${#local_tags} -eq 0 ]]; then
            _error "No local tags found."
            return 1
        fi

        # Try to fetch all existing GitHub release tags using JSON
        local gh_release_tags_text
        gh_release_tags_text=$(gh release list --limit 1000 --json tagName --jq '.[].tagName' 2>/dev/null)

        local -A has_release
        has_release=()
        if [[ -n "$gh_release_tags_text" ]]; then
            local t
            for t in ${(f)gh_release_tags_text}; do
                has_release[$t]=1
            done
        else
            _loading3 "Falling back to per-tag checks (gh JSON not available)"
        fi

        # Determine which local tags do not have a GitHub release
        local -a missing_tags
        missing_tags=()
        local tag_name
        for tag_name in $local_tags; do
            if [[ -n "$gh_release_tags_text" ]]; then
                if [[ -z ${has_release[$tag_name]} ]]; then
                    missing_tags+="$tag_name"
                fi
            else
                if ! gh release view "$tag_name" >/dev/null 2>&1; then
                    missing_tags+="$tag_name"
                fi
            fi
        done

        if [[ ${#missing_tags} -eq 0 ]]; then
            _loading2 "All local tags already have GitHub releases."
            return 0
        fi

        _loading2 "Tags without releases (${#missing_tags}): ${missing_tags[*]}"
        read -q "REPLY?Create releases for these ${#missing_tags} tags? (y/n) "
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            _loading "Aborting."
            return 1
        fi

        # Optionally push tags before creating releases
        read -q "REPLY?Do you want to push all tags before creating releases? (y/n) "
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            _loading "Pushing all tags to origin"
            git push --tags
        fi

        # Create releases for each missing tag
        local msg
        for tag_name in $missing_tags; do
            _loading3 "Creating release for $tag_name"
            msg=$(git log -1 --pretty=%B "$tag_name")
            gh release create "$tag_name" --title "$tag_name" --notes "$msg" || {
                _warning "Failed to create release for $tag_name"
            }
        done
        _success "Bulk release creation complete."
        return 0
    fi

    # Single-tag mode: ensure HEAD is exactly at a tag
    _loading2 "Checking that HEAD is tagged"
    local tag
    tag=$(git describe --tags --exact-match HEAD 2>/dev/null)
    if [[ -z "$tag" ]]; then
        _error "HEAD is not at a tag. Please tag the current commit first."
        return 1
    fi
    _loading3 "HEAD tag: $tag"

    # Check if a GitHub release for this tag already exists
    if gh release view "$tag" >/dev/null 2>&1; then
        _warning "A GitHub release for tag $tag already exists. Nothing to do."
        return 0
    fi

    # Ask to push all tags
    read -q "REPLY?Do you want to push all tags? (y/n) "
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        _loading "Pushing all tags to origin"
        git push --tags
    else
        _loading "Skipping tag push"
    fi

    # Use tag's commit message as release notes
    local msg
    msg=$(git log -1 --pretty=%B "$tag")

    _loading3 "Creating GitHub release for $tag"
    gh release create "$tag" --title "$tag" --notes "$msg"
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

# =====================================
# -- git-storage
# =====================================
help_git[git-storage]="Get git storage information"
function git-storage() {
    # -- Check if git is installed
    [[ ! -x "$(command -v git)" ]] && { _error "Git is not installed";  return 1; }
        
    _loading "Getting git storage information"
    # -- Get git storage information
    _loading2 "Running git count-objects -vH"
    git count-objects -vH

    # -- Find large files
    _loading2 "Finding large files in git history"
    git rev-list --objects --all | \
    git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize:disk) %(rest)' | \
    grep '^blob' | sort -k3 -n -r | head -20 | \
    numfmt --field=3 --to=iec
}

# =====================================
# -- git-prune
# =====================================
help_git[git-prune]="Prune git repository"
function git-prune() {
    _loading2 "Running git gc --aggressive"
    git gc --aggressive
    _loading2 "Running git repack -a -d --depth=250 --window=250"
    git repack -a -d --depth=250 --window=250
    _loading2 "Running git prune"
    git prune
}

# ======================================
# -- git-log-oneline
# ======================================
help_git[git-log-oneline]="Show git log in one line format with commit hash and message"
function git-log-oneline() {
    GIT_COMMIT=${1}
    if [[ -z $GIT_COMMIT ]]; then
        _loading "Showing git log in one line format (deduplicated by message)"
        git log --oneline | awk '{msg=substr($0, index($0,$2)); if (!seen[msg]++) print $1, msg}'
    else
        _loading "Showing git log oneline up to commit: $GIT_COMMIT (deduplicated by message)"
        if ! git rev-parse --verify "$GIT_COMMIT" >/dev/null 2>&1; then
            _error "Commit $GIT_COMMIT not found"
            return 1
        fi
        _loading2 "Showing git log oneline up to commit: $GIT_COMMIT (deduplicated by message)"
        git --no-pager log --no-merges --pretty=format:'%h %s' $GIT_COMMIT..HEAD | awk '{msg=substr($0, index($0,$2)); if (!seen[msg]++) print $1, msg}'
    fi
}

# =====================================
# -- git-squash-release
# =====================================
help_git[git-squash-release]="Squash all commits since the last tag, prompt for minor/major version bump, tag and push"
function git-squash-release() {
    # Parse options
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help

    if [[ -n $opts_help ]]; then
        echo "Usage: git-squash-release [-h|--help]"
        echo ""
        echo "Squash all commits since the last tag into a single release commit."
        echo "Prompts for minor or major version bump, tags the release, and optionally pushes."
        return 0
    fi

    # Find the last tag
    local LAST_TAG
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
    if [[ -z $LAST_TAG ]]; then
        _error "No tags found in this repository."
        return 1
    fi

    # Parse the last tag into major.minor.patch
    local TAG_CLEAN="${LAST_TAG#v}"
    local TAG_MAJOR TAG_MINOR TAG_PATCH
    TAG_MAJOR="${TAG_CLEAN%%.*}"
    TAG_MINOR="${${TAG_CLEAN#*.}%%.*}"
    TAG_PATCH="${TAG_CLEAN##*.}"

    # Calculate minor and major bump versions
    local MINOR_VERSION MAJOR_VERSION
    MINOR_VERSION="${TAG_MAJOR}.${TAG_MINOR}.$(( TAG_PATCH + 1 ))"
    MAJOR_VERSION="${TAG_MAJOR}.$(( TAG_MINOR + 1 )).0"

    # Preserve prefix if original tag had one (e.g. v1.2.3)
    local TAG_PREFIX=""
    if [[ $LAST_TAG == v* ]]; then
        TAG_PREFIX="v"
    fi

    local MINOR_TAG="${TAG_PREFIX}${MINOR_VERSION}"
    local MAJOR_TAG="${TAG_PREFIX}${MAJOR_VERSION}"

    # Find the commit hash for the last tag
    local LAST_TAG_COMMIT
    LAST_TAG_COMMIT=$(git rev-list -n 1 $LAST_TAG)

    # Get deduplicated commit messages since the last tag
    local COMMIT_MSGS
    COMMIT_MSGS=$(git log --oneline $LAST_TAG..HEAD | awk '{msg=substr($0, index($0,$2)); if (!seen[msg]++) print "(" $1 ") " msg}' | paste -sd '\n' -)

    if [[ -z $COMMIT_MSGS ]]; then
        _error "No commits found since $LAST_TAG. Nothing to squash."
        return 1
    fi

    _loading "Last tag: $LAST_TAG ($LAST_TAG_COMMIT)"
    _loading2 "Commits since $LAST_TAG:"
    echo "$COMMIT_MSGS"
    echo ""

    # Prompt for minor or major
    _loading "Select release type:"
    echo "  (i) minor  ($MINOR_TAG)"
    echo "  (a) major  ($MAJOR_TAG)"
    echo "  (c) cancel"
    echo ""

    local RELEASE_TAG
    local REPLY
    read -k 1 "REPLY?Select [i/a/c]: "
    echo ""

    case $REPLY in
        i)
            RELEASE_TAG="$MINOR_TAG"
            _success "Selected minor release: $RELEASE_TAG"
            ;;
        a)
            RELEASE_TAG="$MAJOR_TAG"
            _success "Selected major release: $RELEASE_TAG"
            ;;
        *)
            _warning "Cancelled."
            return 0
            ;;
    esac

    echo ""

    # Perform soft reset to last tag commit
    _loading "Squashing all commits since $LAST_TAG into one..."
    git reset --soft $LAST_TAG_COMMIT

    # Build commit message with release header
    local FINAL_COMMIT_MSG="Release $RELEASE_TAG

$COMMIT_MSGS"

    # Create a new commit with the release message
    git commit -m "$FINAL_COMMIT_MSG"
    _success "Created squashed commit for $RELEASE_TAG"

    # Tag the release
    _loading "Tagging commit as $RELEASE_TAG"
    git tag "$RELEASE_TAG"
    _success "Tagged as $RELEASE_TAG"

    echo ""

    # Ask if we should push
    read -q "REPLY?Push tag and commit with --force? (y/n) "
    echo ""

    if [[ $REPLY == "y" ]]; then
        _loading "Pushing with --force..."
        git push --force
        _loading "Pushing tags..."
        git push --tags
        _success "Release $RELEASE_TAG pushed successfully."
    else
        _warning "Not pushed. To push manually run:"
        echo "  git push --force && git push --tags"
    fi
}

# =====================================
# -- git-do-release
# =====================================
help_git[git-do-release]="Prepend Release <version> to current commit message, tag, and optionally push"
function git-do-release() {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help

    if [[ -n $opts_help ]]; then
        echo "Usage: git-do-release [-h|--help]"
        echo ""
        echo "Prepend the current HEAD commit message with: Release <version>."
        echo "Prompts for minor or major version bump, tags the release, and optionally pushes."
        return 0
    fi

    local LAST_TAG
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
    if [[ -z $LAST_TAG ]]; then
        _error "No tags found in this repository."
        return 1
    fi

    local TAG_CLEAN="${LAST_TAG#v}"
    local TAG_MAJOR TAG_MINOR TAG_PATCH
    TAG_MAJOR="${TAG_CLEAN%%.*}"
    TAG_MINOR="${${TAG_CLEAN#*.}%%.*}"
    TAG_PATCH="${TAG_CLEAN##*.}"

    local MINOR_VERSION MAJOR_VERSION
    MINOR_VERSION="${TAG_MAJOR}.${TAG_MINOR}.$(( TAG_PATCH + 1 ))"
    MAJOR_VERSION="${TAG_MAJOR}.$(( TAG_MINOR + 1 )).0"

    local TAG_PREFIX=""
    if [[ $LAST_TAG == v* ]]; then
        TAG_PREFIX="v"
    fi

    local MINOR_TAG="${TAG_PREFIX}${MINOR_VERSION}"
    local MAJOR_TAG="${TAG_PREFIX}${MAJOR_VERSION}"

    _loading "Last tag: $LAST_TAG"
    _loading2 "HEAD commit: $(git rev-parse --short HEAD)"
    echo ""

    _loading "Select release type:"
    echo "  (i) minor  ($MINOR_TAG)"
    echo "  (a) major  ($MAJOR_TAG)"
    echo "  (c) cancel"
    echo ""

    local RELEASE_TAG
    local REPLY
    read -k 1 "REPLY?Select [i/a/c]: "
    echo ""

    case $REPLY in
        i)
            RELEASE_TAG="$MINOR_TAG"
            _success "Selected minor release: $RELEASE_TAG"
            ;;
        a)
            RELEASE_TAG="$MAJOR_TAG"
            _success "Selected major release: $RELEASE_TAG"
            ;;
        *)
            _warning "Cancelled."
            return 0
            ;;
    esac

    echo ""

    local CURRENT_COMMIT_MSG
    CURRENT_COMMIT_MSG=$(git log -1 --pretty=%B)
    if [[ -z $CURRENT_COMMIT_MSG ]]; then
        _error "Could not read current commit message from HEAD."
        return 1
    fi

    local HEADER_VERSION="${RELEASE_TAG#v}"
    local FINAL_COMMIT_MSG="Release $HEADER_VERSION

$CURRENT_COMMIT_MSG"

    _loading "Updating current commit message with release header..."
    git commit --amend -m "$FINAL_COMMIT_MSG"
    _success "Updated commit message for $RELEASE_TAG"

    _loading "Tagging commit as $RELEASE_TAG"
    git tag "$RELEASE_TAG"
    _success "Tagged as $RELEASE_TAG"

    echo ""

    read -q "REPLY?Push tag and commit with --force? (y/n) "
    echo ""

    if [[ $REPLY == "y" ]]; then
        _loading "Pushing with --force..."
        git push --force
        _loading "Pushing tags..."
        git push --tags
        _success "Release $RELEASE_TAG pushed successfully."
    else
        _warning "Not pushed. To push manually run:"
        echo "  git push --force && git push --tags"
    fi
}