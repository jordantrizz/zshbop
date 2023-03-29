# --
# replace commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[github]="Github related commands"

# - Init help array
typeset -gA help_github

_debug " -- Loading ${(%):-%N}"

# -- paths
help_github[gh-start]='An extension for gh-cli for starting a PR'
function gh-start () {
	echo "Installing gh-start extension from gh extension install https://github.com/balvig/gh-start"
	gh extension install https://github.com/balvig/gh-start
}
