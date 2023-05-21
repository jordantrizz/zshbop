# --
# replace
# --
_debug " -- Loading ${(%):-%N}"
help_files[replace]="replace specific commands" # Help file description
typeset -gA help_replace # Init help array.

# -- paths
help_replace[test]='print out \$PATH on new lines'
test () {
	echo ${PATH:gs/:/\\n}
}