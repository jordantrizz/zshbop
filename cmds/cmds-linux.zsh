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
	function broot () {
		check_broot
	}
	function check_broot () {
		_error "broot not installed" 0
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

# -- ps-cpu
help_linux[ps-cpu]='Show top 5 CPU applications'
ps-cpu () {
    ps aux --sort -pcpu | head -5
}

# -- ps-mem2
help_linux[ps-mem2]='Show memory as human readable and sort'
function ps-mem2() {
    local sortbyfield="rss"
    local fsep="-o zzz:::zzz%% -o"
    local ps_cmd="\ps ax o user:16 $fsep pid $fsep pcpu $fsep pmem $fsep vsz $fsep rss $fsep tty $fsep stat $fsep lstart $fsep time:16 $fsep cmd --sort -$sortbyfield"
    local awk_cmd="awk 'function setprefix(num){{n_suffix=1; while(num > 1000 && n_suffix < suffixes_len) {num /= 1024; n_suffix++;}; num=int(100*num)/100suffixes[n_suffix]}; return num} BEGIN{suffixes_len=split(\"kB MB GB TB PB EB ZB\",suffixes);FS=\"zzz:::zzz%\";} NR>1 {\$5=setprefix(\$5);\$6=setprefix(\$6); }{ printf \"%-16s %6s %-5s %-5s %9s %9s %-8s %-8s %-25s %-18s %s\n\", \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11;}'"
    local cut_cmd="cut -c -250"
    eval "$ps_cmd | $awk_cmd | $cut_cmd"
}

# -- ps-mem
help_linux[ps-mem]="List processes with human readable memory"
ps-mem () {
	# PS_OUTPUT=$(ps -afu | awk 'NR>1 {$5=int($5/1024)"M";} NR>1 {$6=int($6/1024)"M";}{ print;}')
	PS_OUTPUT=$(ps -afu)
	PS_AWK=$(echo $PS_OUTPUT | awk 'BEGIN{ORS=""} NR>1 {$5=int($5/1024)"M"; $6=int($6/1024)"M"; print $1"\t\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t";out="";for(i=11;i<=NF;i++){out=out" "$i};print out;print "\n"}')
	#PS_AWK=$(echo $PS_OUTPUT | awk 'NR>1 {$5=int($5/1024)"M";} NR>1 {$6=int($6/1024)"M";}{ print;}')
	#PS_HEADER=$(echo "$PS_OUTPUT" | head -1)
	PS_HEAD="USER\t\tPID\t%CPU\t%MEM\tVSZ\tRSS\tTTY\tSTAT\tSTART\tTIME\tCOMMAND"
	PS_SEPARATOR="-----------------------------------------------------------------------------------------------"
	PS_HEADER="$PS_SEPARATOR\n$PS_HEAD\n$PS_SEPARATOR"
	# - add header
	i=0
	#PS_FINAL="$PS_AWK"
	PS_AWK2=(${(@f)PS_AWK})
	#PS_FINAL=$PS_AWK2
	#PS_AWK2=(${(s:\n:)PS_AWK})
	#PS_AWK2=$(echo $PS_AWK | tr '\n' '\n')
	#read -A PS_AWK2 <<< "$PS_AWK"
	unset PS_FINAL
	for LINE in ${PS_AWK2[@]}; do
		PS_FINAL+="$LINE\n"
		if [[ $i == "15" ]]; then
			PS_FINAL+="$PS_HEADER\n"
			i=0
		fi
		i=$((i+1))
	done;

	# - print results
	if [[ -n $1 ]]; then
		_notice "Grep'ing for $1"
		echo "$PS_HEADER"
		echo "$PS_FINAL" | \grep -a ${1}
	else
		echo "$PS_HEADER"
		echo "$PS_FINAL"
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
	else
	    _noticebg "systemctl restart $@"
        systemctl restart "$@"
    fi
}

# -- sysrld
help_linux[sysrld]='Systemctl reload shortcut'
sysrld () {
    if [[ -z $@ ]]; then
        echo "systemctl reload - Usage: sysrld [service]"
        return 1
    else
        _noticebg "systemctl reload $@"
        systemctl reload $@
    fi
}


# -- usedspace
help_linux[usedspace]='Show disk space and not count symlinks or tmpfs'
usedspace () {
	find / -maxdepth 1 -type d | xargs du -b --exclude=/proc --exclude=/dev --exclude=/run -h -d 1
}

# -- check_diskspace
help_linux[check_diskspace2]="Check diskspace based on OS"
check_diskspace () {
	check_diskspace_${MACHINE_OS} $@
}

# -- check_blockdevices
check_blockdevices () {
    if [[ $MACHINE_OS == "linux" ]]; then
        OUTPUT=""
        ALERT="98"
        DEVICES=($(lsblk -n -d -o NAME | egrep -v '^loop*'))
        OUTPUT="$fg[cyan]Device Type Size Used% MountPoint${reset_color}"
        for DEVICE in $DEVICES
        do
                TYPE=$(lsblk -n -d -o TYPE /dev/$DEVICE)
                SIZE=$(lsblk -n -d -o SIZE /dev/$DEVICE)
                MOUNT=$(lsblk -n -d -o MOUNTPOINT /dev/$DEVICE)
                USED=$(df -h /dev/$DEVICE | awk '{print $5}' | tail -1)
                OUTPUT+="\n$DEVICE $TYPE $SIZE $USED $MOUNT"
        done
        echo -e "$OUTPUT" | column -t
    else
        _error "check_blockdevices not supported on $MACHINE_OS"
    fi
}

# -- check_diskspace
help_linux[check_diskspace2]="Check diskspace2"
check_diskspace2 () {
	OUTPUT=""
    ALERT="98" # alert level
	# Get a list of storage devices
	DEVICES=($(lsblk -n -d -o NAME | grep -v "^loop"))

	# Loop through each device
	OUTPUT=$(_banner_grey "Device Type Size Used% MountPoint")
	for DEVICE in $DEVICES; do
	    # Get device type
	    TYPE=$(lsblk -n -d -o TYPE /dev/$DEVICE)

	    # Get device size
	    SIZE=$(lsblk -n -d -o SIZE /dev/$DEVICE)

	    # Get mount point
	    MOUNT=$(lsblk -n -d -o MOUNTPOINT /dev/$DEVICE)

	    # Get used percentage
	  	USED=$(df -h /dev/$DEVICE | awk '{print $5}' | tail -1)

	    # Print device information
	    OUTPUT+="\n$DEVICE $TYPE $SIZE $USED $MOUNT"
	done
	echo -e "$OUTPUT" | column -t

}



# -- speed-convert
help_linux[speed-convert]="Convert data speeds"
speed-convert () {
	VALUE="$1"
	UNIT="$2"
	if [[ -z $VALUE || -z $UNIT ]]; then
		echo "Usage: speedconvert <speed> <unit>"
		echo ""
		echo "  Example,   ./speedconvert 1123 MB/s"
		echo ""
	else 
		# Convert value to bytes/second
		case $UNIT in
			"Mbit/s") VALUE=$(echo "$VALUE * 131072" | bc) ;;
			"MB/s") VALUE=$(echo "$VALUE * 1048576" | bc) ;;
			"Gbit/s") VALUE=$(echo "$VALUE * 134217728" | bc -l) ;;
			"GB/s") VALUE=$(echo "$VALUE * 1073741824" | bc -l) ;;
		*) echo "Invalid unit $UNIT" && return 1
		esac
	
		# Convert value to other units
		mbit_s=$(echo "$VALUE / 131072" | bc)
		mb_s=$(echo "$VALUE / 1048576" | bc)
        gbit_s=$(echo "scale=4;$VALUE / 134217728" | bc -l)
		gb_s=$(echo "scale=4;$VALUE / 1073741824" | bc -l)

		# Print results
		echo "$mbit_s MBit/s"
		echo "$mb_s MB/s"
		echo "$gbit_s GBit/s"
		echo "$gb_s GB/s"
	fi
}

# -- utc
help_linux[utc]="Display UTC date and time"
function utc () {
	date -u
}

# -- datetz
help_linux[datetz]="Display specified timezone date and time"
datetz () {
	env TZ=":US/Pacific" date
	env TZ=":US/Central" date	
	env TZ=":US/Eastern" date
	env TZ="UTC" date
}

# -- swappiness
help_linux[swappiness]="Display swappiness"
swappiness () { mem } # alias to mem

# -- ubuntu-lts
help_linux[ubuntu-lts]="Display Ubuntu LTS version"
ubuntu-lts () {
    lts_data=$(curl -s https://changelogs.ubuntu.com/meta-release-lts)
    # Extract the versions and codenames
    VERSION=$(echo "$lts_data" | grep Version: | awk '{print $2}')
    NAME=$(echo "$lts_data" | grep Name: | awk '{print $2}')
    DIST=$(echo "$lts_data" | grep Dist: | awk '{print $2}')
    DATE=$(echo "$lts_data" | grep Date: | awk '{print $4"-"$3"-"$5}')
    SUPPORTED=$(echo "$lts_data" | grep Supported: | awk '{print "Supported: " $2}')

    # Combine the versions and codenames
    combined=$(paste <(echo "$NAME") <(echo "$DIST") <(echo "$VERSION") <(echo "$DATE") <(echo "$SUPPORTED"))

    # Print each version with its codename
    echo "$combined"
}

# -- Screen sessions
help_linux[screen-sessions]="Display screen sessions"
screen-sessions () {
    _cexists screen 
    if [[ $? == "0" ]]; then 
        SCREENS=$(screen -ls)
        if [[ $SCREENS == *"No Sockets found in"* ]]; then
            echo "No screen sessions found"
        else
            [[ $MACHINE_OS == "linux" ]] && { echo $(screen -ls | head -n -1 | awk ' NR>1 { print $1 " " $5 }' | tr '\n' '#' | sed 's/#/ || /g') }
            if [[ $MACHINE_OS == "mac" ]]; then
                SSESIONS=$(_remove_last_line "$(_remove_last_line "$(screen -ls)")")
                echo $SSESIONS | awk ' NR>1 { print $1 " " $4 }' | tr '\n' '#' | sed 's/#/|| /g'
            fi
        fi
    else
        _error "Screen not installed" 0
    fi
}
