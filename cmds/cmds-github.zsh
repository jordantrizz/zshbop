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
	gh repo view --web
}

