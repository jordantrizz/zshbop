# -- github-cli commands
_debug " -- Loading ${(%):-%N}"
help_files[github]="Github related commands"
typeset -gA help_github
_debug " -- Loading ${(%):-%N}"

# ==================================================
# gh-start
# ==================================================
help_github[gh-start]='An extension for gh-cli for starting a PR'
function gh-start () {
	echo "Installing gh-start extension from gh extension install https://github.com/balvig/gh-start"
	gh extension install https://github.com/balvig/gh-start
}

# ==================================================
# gh-web
# ==================================================
help_github[gh-web]='Open the current repository in the browser'
function gh-web () {
	MODE=${1:=0}
	_debug "MODE: $MODE"

	_gh_web_gh () {
		gh repo view --web		
	}

	_gh_web_alt () {
		remote_url=$(git config --get remote.origin.url)
		if [[ $remote_url == *github.com* ]]; then
			repo_url=${remote_url%.git}
			repo_url=${repo_url/github.com:/github.com\/}
			repo_url=${repo_url/git\@/https:\/\/}
			echo "Repo URL is $repo_url"
		else
			echo "This doesn't seem to be a GitHub repository. Run 'git config --get remote.origin.url' to see the remote URL."
		fi
	
	}
	_cmd_exists gh
	if [[ $? == 0 ]] && [[ $MODE == "0" ]]; then
		_gh_web_gh
	elif [[ $MODE == "1" ]]; then
		_gh_web_alt
	else
		_gh_web_alt
	fi

}

# ==================================================
# gh-repos
# ==================================================
help_github[gh-repos]='List all repos for gh-cli (cached per mode, 2-day freshness)'
function gh-repos () {
	_debug_all

	local -a ALL NOCACHE ORGS PERSONAL HELP
	local MODE
	local GH_ORGS GH_REPOS GH_PERSONAL_REPOS
	local ORGS_ENABLED PERSONAL_ENABLED
	local CACHE_TTL CACHE_MAX_AGE CACHE_DIR
	local CACHE_FILE CACHE_TS_FILE CACHE_AGE AGE_DAYS
	local PERSONAL_JSON ORGS_JSON ORG_REPOS_JSON
	local ORG REPO REPO_NAME REPO_PRIVATE
	local OUTPUT

	# -- Parse arguments
	zparseopts -D -E -- h=HELP -help=HELP all=ALL -all=ALL nocache=NOCACHE -nocache=NOCACHE orgs=ORGS -orgs=ORGS personal=PERSONAL -personal=PERSONAL

	if [[ -n $HELP ]]; then
		echo "Usage: gh-repos [-all] [-orgs] [-personal] [-nocache] [-h|--help]"
		echo ""
		echo "List GitHub repos via gh-cli. Output is cached per request mode"
		echo "under \$ZSHBOP_CACHE_DIR/gh-repos/ for up to 2 days (silent serve),"
		echo "with a staleness warning between 2-7 days and an expiry prompt"
		echo "to regenerate once past 7 days."
		echo ""
		echo "Options:"
		echo "  -all        List organization and personal repos (mode: all)"
		echo "  -orgs       List organization repos only (mode: orgs)"
		echo "  -personal   List personal repos only (mode: personal, default)"
		echo "  -nocache    Bypass the cache entirely (no read, no write)"
		echo "  -h, --help  Show this help"
		echo ""
		echo "Environment overrides:"
		echo "  GH_REPOS_CACHE_TTL        Cache freshness in seconds (default: 172800 = 2 days)"
		echo "  GH_REPOS_CACHE_MAX_AGE    Expiry prompt threshold in seconds (default: 604800 = 7 days)"
		return 0
	fi

	# -- Determine the cache mode from the requested flags
	if [[ -n $ALL ]]; then
		MODE="all"
		ORGS_ENABLED="1"
		PERSONAL_ENABLED="1"
	elif [[ -n $ORGS ]]; then
		MODE="orgs"
		ORGS_ENABLED="1"
		PERSONAL_ENABLED="0"
	elif [[ -n $PERSONAL ]]; then
		MODE="personal"
		ORGS_ENABLED="0"
		PERSONAL_ENABLED="1"
	else
		MODE="personal"
		ORGS_ENABLED="0"
		PERSONAL_ENABLED="1"
	fi

	# -- Check if gh-cli is installed
	_cmd_exists gh
	[[ $? == "1" ]] && { _error "gh-cli is not installed"; return 1 }

	# -- Check if jq is installed
	_cmd_exists jq
	[[ $? == "1" ]] && { _error "jq is not installed"; return 1 }

	# -- Check gh auth
	gh auth status >/dev/null 2>&1
	[[ $? != "0" ]] && { _error "gh-cli is not authenticated. Run: gh auth login"; return 1 }

	# -- Cache configuration (per-mode cache files)
	CACHE_TTL="${GH_REPOS_CACHE_TTL:-172800}"          # 2 days (serve fresh)
	CACHE_MAX_AGE="${GH_REPOS_CACHE_MAX_AGE:-604800}"  # 7 days (expiry prompt)
	CACHE_DIR="${ZSHBOP_CACHE_DIR}/gh-repos"
	mkdir -p "$CACHE_DIR"
	CACHE_FILE="${CACHE_DIR}/${MODE}.txt"
	CACHE_TS_FILE="${CACHE_DIR}/${MODE}.ts"

	# -- Print cache age in seconds for a mode, or -1 when missing/invalid
	_gh_repos_cache_age () {
		local TS_FILE=$1
		local NOW TS

		[[ -n $NOCACHE ]] && { print -r -- -1; return 0 }
		[[ -f "$TS_FILE" ]] || { print -r -- -1; return 0 }

		TS=$(<"$TS_FILE")
		[[ "$TS" == <-> ]] || { print -r -- -1; return 0 }

		NOW=$(date +%s)
		print -r -- $(( NOW - TS ))
	}

	# -- Render a loading header into the output buffer (respects QUIET)
	_gh_repos_add_header () {
		local LEVEL=$1 MSG=$2 LINE
		[[ "${QUIET:-0}" == "1" ]] && return 0
		if [[ "$LEVEL" == "2" ]]; then
			LINE=$( _loading2 "$MSG" )
		else
			LINE=$( _loading "$MSG" )
		fi
		OUTPUT+="$LINE"$'\n'
	}

	# -- Ask the user to expire and regenerate a stale cache; auto-regenerates when non-interactive
	_gh_repos_expire_prompt () {
		local AGE_DAYS=$1 ANSWER

		# -- Non-interactive shell: regenerate automatically instead of hanging
		if [[ ! -t 0 ]]; then
			_warning "Cache for mode: $MODE is ${AGE_DAYS} day(s) old; regenerating automatically"
			return 0
		fi

		print -rn -- "Cache for mode: $MODE is ${AGE_DAYS} day(s) old. Expire and regenerate? [y/N] "
		read -r ANSWER
		[[ "$ANSWER" == [yY]* ]]
	}

	# -- Serve from the per-mode cache
	CACHE_AGE=$(_gh_repos_cache_age "$CACHE_TS_FILE")
	if (( CACHE_AGE >= 0 )) && [[ -f "$CACHE_FILE" ]]; then
		# -- Fresh (up to 2 days): serve silently
		if (( CACHE_AGE < CACHE_TTL )); then
			_debug "Using cached listing for mode: $MODE"
			cat "$CACHE_FILE"
			return 0
		fi

		AGE_DAYS=$(( CACHE_AGE / 86400 ))

		# -- Past 7 days: ask to expire and regenerate
		if (( CACHE_AGE > CACHE_MAX_AGE )); then
			if _gh_repos_expire_prompt "$AGE_DAYS"; then
				_debug "Expiring stale cache for mode: $MODE and regenerating"
			else
				_warning "Keeping stale cache for mode: $MODE (${AGE_DAYS} day(s) old)"
				cat "$CACHE_FILE"
				return 0
			fi
		else
			# -- 2-7 days: warn and serve the stale cache
			_warning "Using stale cache for mode: $MODE (${AGE_DAYS} day(s) old)"
			cat "$CACHE_FILE"
			return 0
		fi
	fi

	OUTPUT=""

	# -- Build org repos output
	if [[ "$ORGS_ENABLED" == "1" ]]; then
		_gh_repos_add_header 1 "Listing organization github.com repos"

		ORGS_JSON=$(gh api "/user/orgs?per_page=100" --paginate 2>/dev/null)
		if [[ $? != "0" ]]; then
			_error "Unable to fetch organizations from gh-cli"
			return 1
		fi

		GH_ORGS=(${(f)"$(print -r -- "$ORGS_JSON" | jq -r '.[].login' 2>/dev/null)"})
		if [[ $? != "0" ]]; then
			_error "Unable to parse organization response"
			return 1
		fi

		for ORG in ${GH_ORGS[@]}; do
			_gh_repos_add_header 2 "Listing repos for $ORG"

			ORG_REPOS_JSON=$(gh api "/orgs/${ORG}/repos?per_page=100&type=all" --paginate 2>/dev/null)
			if [[ $? != "0" ]]; then
				_warning "Unable to fetch repos for org ${ORG}"
				continue
			fi

			GH_REPOS=$(print -r -- "$ORG_REPOS_JSON" | jq -r '.[] | "\(.name)\t\(.private)"' 2>/dev/null)
			if [[ $? != "0" ]]; then
				_warning "Unable to parse repos for org ${ORG}"
				continue
			fi

			for REPO in ${(f)GH_REPOS}; do
				REPO_NAME=${REPO%%$'\t'*}
				REPO_PRIVATE=${REPO#*$'\t'}
				if [[ "$REPO_PRIVATE" == "true" ]]; then
					OUTPUT+=" - ${ORG}/${REPO_NAME} - ${bg[red]}Private${RSC}"$'\n'
				else
					OUTPUT+=" - ${ORG}/${REPO_NAME}"$'\n'
				fi
			done
		done
	fi

	# -- Build personal repos output
	if [[ "$PERSONAL_ENABLED" == "1" ]]; then
		_gh_repos_add_header 1 "Listing personal github.com repos"

		PERSONAL_JSON=$(gh api "/user/repos?per_page=100&type=owner" --paginate 2>/dev/null)
		if [[ $? != "0" ]]; then
			_error "Unable to fetch personal repos from gh-cli"
			return 1
		fi

		GH_PERSONAL_REPOS=$(print -r -- "$PERSONAL_JSON" | jq -r '.[] | "\(.name)\t\(.private)"' 2>/dev/null)
		if [[ $? != "0" ]]; then
			_error "Unable to parse personal repos response"
			return 1
		fi

		for REPO in ${(f)GH_PERSONAL_REPOS}; do
			REPO_NAME=${REPO%%$'\t'*}
			REPO_PRIVATE=${REPO#*$'\t'}
			if [[ "$REPO_PRIVATE" == "true" ]]; then
				OUTPUT+="${REPO_NAME} - ${bg[red]}Private${RSC}"$'\n'
			else
				OUTPUT+="${REPO_NAME}"$'\n'
			fi
		done
	fi

	# -- Print the output and store it in the per-mode cache
	print -r -- "$OUTPUT"
	if [[ -z $NOCACHE ]]; then
		print -r -- "$OUTPUT" >| "$CACHE_FILE"
		print -r -- "$(date +%s)" >| "$CACHE_TS_FILE"
		_debug "Cached listing for mode: $MODE"
	fi
	return 0
}


