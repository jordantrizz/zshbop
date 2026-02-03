# -- github-cli commands
_debug " -- Loading ${(%):-%N}"
help_files[github]="Github related commands"
typeset -gA help_github
_debug " -- Loading ${(%):-%N}"

# =============================================================================
# gh-start
# ===============================================
help_github[gh-start]='An extension for gh-cli for starting a PR'
function gh-start () {
	echo "Installing gh-start extension from gh extension install https://github.com/balvig/gh-start"
	gh extension install https://github.com/balvig/gh-start
}

# ===============================================
# gh-web
# ===============================================
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


