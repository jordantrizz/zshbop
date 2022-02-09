# --
# Linux commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[linux]='Linux related commands'

# - Init help array
typeset -gA help_linux

# -- findswap - find what's using swap.
help_linux[findswap]='Find what processes are using swap.'
findswap () { 
	find /proc -maxdepth 2 -path "/proc/[0-9]*/status" -readable -exec awk -v FS=":" '{process[$1]=$2;sub(/^[ \t]+/,"",process[$1]);} END {if(process["VmSwap"] && process["VmSwap"] != "0 kB") printf "%10s %-30s %20s\n",process["Pid"],process["Name"],process["VmSwap"]}' '{}' \; | awk '{print $(NF-1),$0}' | sort -h | cut -d " " -f2- 
}

# -- dir-filecount
help_linux[dir-filecount]='Count how many files are in each directory, recusively and report back a total.'
dir-filecount () {
	find -maxdepth 1 -type d | sort | while read -r dir; do n=$(find "$dir" -type f | wc -l); printf "%4d : %s\n" $n "$dir"; done
}