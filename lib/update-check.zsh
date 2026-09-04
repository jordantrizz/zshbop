#!/usr/bin/env zsh
# =================================================================================================
# -- update-check.zsh -- Branch-aware zshbop update detection
# -- main:          compares release tags (can be N releases behind)
# -- next-release:  tracks origin/next-release HEAD (tags + single commits)
# -- Pure git, no GitHub API / curl / jq.
# =================================================================================================
_debug_load

# ==============================================
# -- zshbop-check-update () - Check for zshbop updates
# -- Tags on main, commits on next-release
# -- Command entry: zshbop check-updates (see zshbop_check-updates wrapper)
# ==============================================
function zshbop-check-update () {
    # Parse options with zparseopts
    local -a opts_help opts_verbose opts_root opts_motd
    local root="" branch="" verbose=0 motd_mode=0
    zparseopts -D -E -- h=opts_help -help=opts_help v=opts_verbose -verbose=opts_verbose r:=opts_root -root:=opts_root m=opts_motd -motd=opts_motd

    if [[ -n $opts_help ]]; then
        echo "Usage: zshbop-check-update [-h|--help] [-v|--verbose] [-r|--root <path>] [-m|--motd]"
        echo ""
        echo "Check if a zshbop update is available (git only, no GitHub API)."
        echo ""
        echo "  -h, --help          Show this help and exit"
        echo "  -v, --verbose       Print extra detail"
        echo "  -r, --root <path>   Repo root to check (default: \$ZSHBOP_ROOT)"
        echo "  -m, --motd          MOTD mode - only print when an update is available"
        echo ""
        echo "Branch behavior:"
        echo "  main          - Compares release tags; may be N releases behind"
        echo "  next-release  - Compares commits vs origin/next-release"
        return 0
    fi

    [[ -n $opts_verbose ]] && verbose=1
    [[ -n $opts_motd ]] && motd_mode=1
    root="${opts_root[2]:-$ZSHBOP_ROOT}"
    [[ -z "$root" ]] && { _error "No zshbop root found, use -r|--root <path>"; return 1 }

    # -- Validate the repo root
    git --git-dir=$root/.git --work-tree=$root rev-parse --is-inside-work-tree > /dev/null 2>&1
    if [[ $? -ge 1 ]]; then
        [[ $motd_mode -eq 0 ]] && _error "Invalid zshbop repository at $root"
        return 1
    fi

    # -- System installs are root-owned; git fetch needs write access to .git/FETCH_HEAD
    if [[ ! -w "$root/.git" ]]; then
        if [[ $motd_mode -eq 1 ]]; then
            _debug "Update check skipped: $root/.git not writable by $(id -un)"
            return 0
        fi
        _warning "zshbop repo at $root is not writable by $(id -un) - run 'sudo zshbop check-updates' or fix ownership"
        return 0
    fi

    branch=$(git --git-dir=$root/.git --work-tree=$root rev-parse --abbrev-ref HEAD)
    if [[ $? -ge 1 ]] || [[ -z "$branch" ]]; then
        _error "Failed to detect current branch"
        return 1
    fi

    [[ $motd_mode -eq 0 ]] && _loading "Checking for zshbop updates ($branch)"
    [[ $verbose -eq 1 ]] && _loading3 "Checking $root"

    case $branch in
        main)          _update_check_main "$root" "$verbose" "$motd_mode" ;;
        next-release)  _update_check_next "$root" "$verbose" "$motd_mode" ;;
        *)
            _error "Updater only supports main and next-release branches. Current branch: $branch"
            return 1
            ;;
    esac
}

# ==============================================
# -- _update_check_main () - Compare release tags on main
# -- The latest tag on origin/main can be ahead by one, two or many releases
# ==============================================
function _update_check_main () {
    local root="$1" verbose="$2" motd_mode="$3"
    local current_tag="" latest_tag="" behind=0 idx=0 found=0 i
    local -a version_tags=()

    [[ $motd_mode -eq 0 ]] && _loading2 "Checking release tags on origin/main"
    [[ $verbose -eq 1 ]] && _loading3 "Fetching origin/main"
    git --git-dir=$root/.git --work-tree=$root fetch origin main --quiet
    if [[ $? -ge 1 ]]; then
        [[ $motd_mode -eq 0 ]] && _error "Failed to fetch origin/main"
        return 1
    fi

    [[ $verbose -eq 1 ]] && _loading3 "Fetching origin tags"
    git --git-dir=$root/.git --work-tree=$root fetch origin --tags --quiet
    if [[ $? -ge 1 ]]; then
        [[ $motd_mode -eq 0 ]] && _error "Failed to fetch tags from origin"
        return 1
    fi

    # -- Current release tag, fall back to $ZSHBOP_VERSION when describe fails
    current_tag=$(git --git-dir=$root/.git --work-tree=$root describe --tags --abbrev=0 HEAD 2>/dev/null)
    [[ -z "$current_tag" ]] && current_tag="$ZSHBOP_VERSION"
    if [[ -z "$current_tag" ]]; then
        [[ $motd_mode -eq 0 ]] && _error "Could not determine current release"
        return 1
    fi

    # -- Version tags only (excludes junk tags like "push")
    version_tags=($(git --git-dir=$root/.git --work-tree=$root tag --sort=v:refname | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'))
    if [[ ${#version_tags} -eq 0 ]]; then
        [[ $motd_mode -eq 0 ]] && _warning "No version tags found, unable to compare releases"
        return 1
    fi

    latest_tag="${version_tags[-1]}"

    # -- Releases behind = position of current tag in the sorted list
    for i in "${version_tags[@]}"; do
        (( idx++ ))
        if [[ "$i" == "$current_tag" ]]; then
            found=1
            break
        fi
    done

    [[ $verbose -eq 1 ]] && _loading3 "Local release $current_tag | Latest release $latest_tag | ${#version_tags} version tags"

    if [[ $found -eq 0 ]]; then
        [[ $motd_mode -eq 0 ]] && _warning "Local release $current_tag not on origin — you are ahead of or off the remote release list (latest: $latest_tag)"
        return 0
    fi

    behind=$(( ${#version_tags} - idx ))

    if [[ $behind -eq 0 ]]; then
        [[ $motd_mode -eq 0 ]] && _success "On latest release $latest_tag"
    else
        _warning "zshbop update available: $current_tag → $latest_tag ($behind release(s) behind) - run 'zbu' to update"
    fi
    return 0
}

# ==============================================
# -- _update_check_next () - Compare commits on next-release
# -- Tags AND single commits: always track origin/next-release HEAD
# ==============================================
function _update_check_next () {
    local root="$1" verbose="$2" motd_mode="$3"
    local behind=""

    [[ $motd_mode -eq 0 ]] && _loading2 "Checking commits on origin/next-release"
    [[ $verbose -eq 1 ]] && _loading3 "Fetching origin/next-release"
    git --git-dir=$root/.git --work-tree=$root fetch origin next-release --quiet
    if [[ $? -ge 1 ]]; then
        [[ $motd_mode -eq 0 ]] && _error "Failed to fetch origin/next-release"
        return 1
    fi

    behind=$(git --git-dir=$root/.git --work-tree=$root rev-list --count HEAD..origin/next-release 2>/dev/null)
    if [[ $? -ge 1 ]]; then
        [[ $motd_mode -eq 0 ]] && _error "Failed to compare commits with origin/next-release"
        return 1
    fi
    if [[ "$behind" != <-> ]]; then
        [[ $motd_mode -eq 0 ]] && _error "Unexpected commit count from git: $behind"
        return 1
    fi

    if [[ $behind -eq 0 ]]; then
        [[ $motd_mode -eq 0 ]] && _success "No update, on latest origin/next-release"
    else
        _warning "zshbop update available: $behind commit(s) behind origin/next-release - run 'zbu' to update"
    fi
    return 0
}
