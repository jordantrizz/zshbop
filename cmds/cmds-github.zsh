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
	if _cmd_exists "gh"; then
		gh repo view --web
	else
		remote_url=$(git config --get remote.origin.url)
		if [[ $remote_url == *github.com* ]]; then
			repo_url=${remote_url%.git}
			repo_url=${repo_url/github.com/github.com\/(open)}
			echo "Repo URL is $repo_url"			
		else
			echo "This doesn't seem to be a GitHub repository."
		fi
	fi
}


