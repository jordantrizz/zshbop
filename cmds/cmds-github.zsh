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
help_github[gh-repos]='List all repos for gh-cli'
function gh-repos () {
	_debug_all

	local -a ALL NOCACHE ORGS PERSONAL HELP
	local GH_ORGS GH_REPOS GH_PERSONAL_REPOS
	local ORGS_ENABLED PERSONAL_ENABLED
	local CACHE_TTL CACHE_DIR
	local CACHE_PERSONAL CACHE_PERSONAL_TS
	local CACHE_ORGS CACHE_ORGS_TS
	local PERSONAL_JSON ORGS_JSON ORG_REPOS_JSON
	local ORG REPO REPO_NAME REPO_PRIVATE

	# -- Parse arguments
	zparseopts -D -E -- h=HELP -help=HELP all=ALL nocache=NOCACHE orgs=ORGS personal=PERSONAL

	if [[ -n $HELP ]]; then
		echo "Usage: gh-repos [-all] [-orgs] [-personal] [-nocache] [-h|--help]"
		return 0
	fi

	if [[ -n $ALL ]]; then
		ORGS_ENABLED="1"
		PERSONAL_ENABLED="1"
	elif [[ -n $ORGS ]]; then
		ORGS_ENABLED="1"
		PERSONAL_ENABLED="0"
	elif [[ -n $PERSONAL ]]; then
		ORGS_ENABLED="0"
		PERSONAL_ENABLED="1"
	else
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

	# -- Cache configuration
	CACHE_TTL="${GH_REPOS_CACHE_TTL:-600}"
	CACHE_DIR="${ZSHBOP_CACHE_DIR}/gh-repos"
	mkdir -p "$CACHE_DIR"
	CACHE_PERSONAL="${CACHE_DIR}/personal.json"
	CACHE_PERSONAL_TS="${CACHE_DIR}/personal.ts"
	CACHE_ORGS="${CACHE_DIR}/orgs.json"
	CACHE_ORGS_TS="${CACHE_DIR}/orgs.ts"

	_cache_valid_gh_repos () {
		local TS_FILE=$1
		local NOW TS

		[[ -n $NOCACHE ]] && return 1
		[[ -f "$TS_FILE" ]] || return 1

		TS=$(<"$TS_FILE")
		[[ "$TS" == <-> ]] || return 1

		NOW=$(date +%s)
		(( NOW - TS < CACHE_TTL ))
	}

	# -- Check if we're listing org repos
	if [[ "$ORGS_ENABLED" == "1" ]]; then
		_loading "Listing organization github.com repos"

		if _cache_valid_gh_repos "$CACHE_ORGS_TS" && [[ -f "$CACHE_ORGS" ]]; then
			_debug "Using org cache"
			ORGS_JSON=$(<"$CACHE_ORGS")
		else
			ORGS_JSON=$(gh api "/user/orgs?per_page=100" --paginate 2>/dev/null)
			if [[ $? != "0" ]]; then
				_error "Unable to fetch organizations from gh-cli"
				return 1
			fi
			print -r -- "$ORGS_JSON" >| "$CACHE_ORGS"
			print -r -- "$(date +%s)" >| "$CACHE_ORGS_TS"
		fi

		GH_ORGS=(${(f)$(print -r -- "$ORGS_JSON" | jq -r '.[].login' 2>/dev/null)})
		if [[ $? != "0" ]]; then
			_error "Unable to parse organization response"
			return 1
		fi

		for ORG in ${GH_ORGS[@]}; do
			_loading2 "Listing repos for $ORG"

			if _cache_valid_gh_repos "${CACHE_DIR}/org-${ORG}.ts" && [[ -f "${CACHE_DIR}/org-${ORG}.json" ]]; then
				ORG_REPOS_JSON=$(<"${CACHE_DIR}/org-${ORG}.json")
			else
				ORG_REPOS_JSON=$(gh api "/orgs/${ORG}/repos?per_page=100&type=all" --paginate 2>/dev/null)
				if [[ $? != "0" ]]; then
					_warning "Unable to fetch repos for org ${ORG}"
					continue
				fi
				print -r -- "$ORG_REPOS_JSON" >| "${CACHE_DIR}/org-${ORG}.json"
				print -r -- "$(date +%s)" >| "${CACHE_DIR}/org-${ORG}.ts"
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
					echo " - $ORG/$REPO_NAME - ${bg[red]}Private${RSC}"
				else
					echo " - $ORG/$REPO_NAME"
				fi
			done
		done
	fi

	# -- Check if we're listing personal repos
	if [[ "$PERSONAL_ENABLED" == "1" ]]; then
		_loading "Listing personal github.com repos"

		if _cache_valid_gh_repos "$CACHE_PERSONAL_TS" && [[ -f "$CACHE_PERSONAL" ]]; then
			_debug "Using personal cache"
			PERSONAL_JSON=$(<"$CACHE_PERSONAL")
		else
			PERSONAL_JSON=$(gh api "/user/repos?per_page=100&type=owner" --paginate 2>/dev/null)
			if [[ $? != "0" ]]; then
				_error "Unable to fetch personal repos from gh-cli"
				return 1
			fi
			print -r -- "$PERSONAL_JSON" >| "$CACHE_PERSONAL"
			print -r -- "$(date +%s)" >| "$CACHE_PERSONAL_TS"
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
				echo "$REPO_NAME - ${bg[red]}Private${RSC}"
			else
				echo "$REPO_NAME"
			fi
		done
	fi
}


