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

# -- vhwinfo - Run vhwinfo.
help_linux[vhwinfo]='Temporarily downloads vhwinfo and displays system information.'
vhwinfo () {
        echo " -- Downloading vhwinfo.sh via wget and running"
        wget --no-check-certificate https://github.com/rafa3d/vHWINFO/raw/master/vhwinfo.sh -O - -o /dev/null|bash
}

# -- needrestart - check if system needs a restart
help_linux[needrestart]='Check if system needs a restart'
_cexists needrestart
if [[ $? == "1" ]]; then
	needrestart () {
		_debug "needrestart not installed"
		_notice "needrestart not installed"
		echo 'Press any key to install needrestart...'; read -k1 -s
		sudo apt-get install needrestart
	}
fi

# -- broot -
help_linux[broot]='Get an overview of a directory, even a big one'
_cexists broot
if [[ $? == "1" ]]; then
	broot () {
		check_broot
	}
	check_broot () {
		_error "broot not installed"
	}
fi

# -- backup
help_linux[backup]='Backup a folder in a tar file'
backup () {
	if [[ -z $1 ]]; then
		echo "Usage: backup <folder>"
		return
	fi
	if [[ ! -d $1 ]]; then
		_error "Folder $1 doesn't exist...exiting"
		return
	else
		TAR_BACKUP_DATE=`date +%m-%d-%Y`
		echo "Backing up folder $1 to $1-${TAR_BACKUP_DATE}.tar"
		echo ""
		tar -cvf $1-${TAR_BACKUP_DATE}.tar $1
		echo ""
		echo "Completed backup of $1 to $1-${TAR_BACKUP_DATE}.tar"
	fi
}		

# -- ps2
help_linux[ps2]='Show long usernames in ps :)'
ps2 () {
    if [[ $@ =~ .u* ]] || [[ *u ]]; then
        command getent passwd |\
        awk -F':' ' \
        !len || length($1) > len {len=length($1);s=$1}\
        END{print s, len; system("ps awwfxo user:"len",pid,pcpu,pmem,vsz,rss,tty,stat,start,time,args");}'
    else
        command ps "$@"
    fi
}

# -- fork
help_linux[fork]='Fork command into background'
fork () { 
	(setsid "$@" &); 
}

# -- sysr
help_linux[sysr]='Systemctl restart shortcut'
sysr () {
	if [[ -z $@ ]]; then
		echo "systemctl restart - Usage: sysr [service]"
		return 1
	fi
	systemctl restart $@
}

# -- ps-cpu
help_linux[ps-cpu]='Show top 5 CPU applications'
ps-cpu () {
    ps aux --sort -pcpu | head -5
}

# -- usedspace
help_linux[usedspace]='Show disk space and not count symlinks or tmpfs'
usedspace () {
	find / -maxdepth 1 -type d | xargs du -b --exclude=/proc --exclude=/dev --exclude=/run -h -d 1
}