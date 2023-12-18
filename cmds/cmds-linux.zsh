# -- Linux commands
_debug " -- Loading ${(%):-%N}"

help_files[linux]='Linux related commands'

# - Init help array
typeset -gA help_linux

# -- swap-find - find what's using swap.
help_linux[swap-find]='Find what processes are using swap.'
swap-find () {
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
_cmd_exists needrestart
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
_cmd_exists broot
if [[ $? == "1" ]]; then
	function broot () {
		check_broot
	}
	function check_broot () {
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
# -- syss
help_linux[syss]='Systemctl status shortcut'
syss () {
	if [[ -z $@ ]]; then
		echo "systemctl status - Usage: syss [service]"
		return 1
	else
	    _noticebg "systemctl status $@"
        systemctl status "$@"
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

# -- check-diskspace
help_linux[check-diskspace]="Check diskspace based on OS"
check-diskspace () {
	if [[ $MACHINE_OS == "linux" ]]; then
		linux-checkdiskspace
	else
		_error "check-diskspace not supported on $MACHINE_OS"
	fi
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
	local SSESSIONS_OUTPUT SSESSIONS
	# -- Check if on WSL
	if [[ $MACHINE_OS2 == "wsl" && ! -d "/run/screen" ]]; then
		_loading3 "Detect wsl, running wsl-screen fix"
		wsl-screen
	fi

    _cmd_exists screen
    if [[ $? == "0" ]]; then
        SCREENS=$(screen -ls)
		SCREEN_EXIT_CODE=$?

		if [[ $SCREENS == *"No Sockets found in"* ]]; then
            _warning "No screen sessions found"
		elif [[ $SCREEN_EXIT_CODE == "1" ]]; then
			SCREENS=$(echo $SCREENS | tr -d '\r')
			_error "Screen error - $SCREEN_EXIT_CODE - $SCREENS"
        else
            if [[ $MACHINE_OS == "linux" ]]; then
				SSESSIONS_OUTPUT=$(echo $(screen -ls | head -n -1 | awk ' NR>1 { print $1 " " $5 }' | tr '\n' '#' | sed 's/#/ || /g'))
			elif [[ $MACHINE_OS == "mac" ]]; then
                SSESIONS=$(_remove_last_line "$(_remove_last_line "$(screen -ls)")")
                SSESSIONS_OUTPUT=$(echo $SSESIONS | awk ' NR>1 { print $1 " " $4 }' | tr '\n' '#' | sed 's/#/|| /g')
            fi
			echo "$(_loading2 Screen Sessions:) $(_loading3b $SSESSIONS_OUTPUT)"
        fi
    else
        _error "Screen not installed"
    fi
}

# -- rename-ext
help_linux[rename-ext]='Rename file extensions'
rename-ext () {
        if [[ -z $1 ]] || [[ -z $2 ]]; then
	        echo "Usage: rename-ext <old extension> <new extension>"
        else
                for f in *.$1; do
                        #echo "mv -- \"$f\" \"${f%.$1}.$2\""
                        mv -- "$f" "${f%.$1}.$2"
                done
        fi
}

# -- add-path
help_linux[add-path]='Add to $PATH'
add-path () {
	if [[ -z $1 ]]; then
		echo "Usage: add-path <path>"
		return 1
	else
		export PATH=$PATH:$@
	fi
}

# -- paths
help_linux[paths]='print out \$PATH on new lines'
paths () {
	echo ${PATH:gs/:/\\n}
}

# -- catvet
help_linux[catvet]='Print out special formatting characters in a file or via pipe'
catvet () {
	echo "To print out the special formatting characters..."
	echo "echo 'testing\n' | cat -vet"
}

# -- view-std
help_linux[view-std]='View standard output and error'
view-std () {
	if [[ -z $1 ]]; then
		echo "Usage: view-std <command>"
		return 1
	else
		eval "{ { $1; } 2>&3 | sed 's/^/STDOUT: /'; } 3>&1 1>&2 | sed 's/^/STDERR: /'"
	fi
}

help_linux[get-os-install-date]='Get the date the OS was installed'
alias get-os-install-date="_get_os_install_date"

# -- swappiness-set <size> - set swap size
help_linux[swappiness-set]='Set swappiness'
swappiness-set () {
	if [[ -z $1 ]]; then
		echo "Usage: swappiness-set <size>"
		echo "Current swappiness: $(sysctl vm.swappiness)"
		return 1
	else
		echo "Setting swappiness to $1"
		sudo sysctl vm.swappiness=$1
	fi
}

# -- Reset Swap
help_linux[swap-reset]='Reset swap'
swap-reset () {
	# -- Check if swap is on or off
	SWAP_ON=$(swapon -s)
	if [[ -z $SWAP_ON ]]; then
		echo "Swap is off"
		swapon -a
	else
		echo "Swap is on, turning off then back on."
		# -- Swap is on, turn off
		swapoff -a
		# -- Turn swap back on
		swapon -a
	fi
}

# ====================================
# -- linux - list all linux flavours and versions with code names
# ====================================
help_linux[linux]='List all linux flavours and versions with code names'
linux () {
	# List past and current debian versions and codenames, stable testing and EOL dates

	# -- Debian
	_loading "Debian versions:"
	cat <<- ENDF
	The next release of Debian is codenamed trixie — testing — no release date has been set
	--
	Debian 12 (bookworm) — current stable release
	Debian 11 (bullseye) — current oldstable release
	Debian 10 (buster) — current oldoldstable release, under LTS support
	ENDF

	# -- Ubuntu
	_loading "Ubuntu versions:"
	cat <<- ENDF
	The next release of Ubuntu is codenamed Mantic Minotaur - released October 12, 2023"
	--
	Ubuntu 22.04 LTS (Jammy Jellyfish) — Current LTS - Standard Support April 2027 - EOL April 2032
	Ubuntu 20.04 LTS (Focal Fossa) — Standard Support April 2025 - EOL April 2030
	Ubuntu 18.04 LTS (Bionic Beaver) — Standard Support June 2023 - EOL April 2028
	Ubuntu 16.04 LTS (Xenial Xerus) — Standard Support April 2021 - EOL April 2026
	ENDF

}


# ==================================================
# -- date override
# ==================================================
help_linux['date-more']='Show current date and C.UTF-8 date'
function date-more () {
    # Show current date
    echo "System: $(/bin/date)"
    echo "-------------------------------------"
    # Show C.UTF-8 date
    echo "C.UTF-8: $(LC_ALL=C.UTF-8 /bin/date)"
}


# =================================================================================================
# -- lsof-mem
# =================================================================================================
help_linux[lsof-mem]='List memory usage of a process'
lsof-mem () {
	local PID=$1
	# Default to human readable unless defined.
	local OUTPUT=${2:-"-hr"}
	if [[ -z $PID ]]; then
		echo "Usage: lsof-mem <pid> (-hr|-mr|-mem) (human readable|machine readable|memory only)"
		return 1
	else
		if [[ $OUTPUT == "-hr" ]]; then
			lsof -p $PID | grep 'mem' | awk '{print $9, $7/(1024*1024) " MB"}' | sort -k2 -n
		elif [[ $OUTPUT == "-mr" ]]; then
			lsof -p $PID | grep 'mem' | awk '{print $9, $7}' | sort -k2 -n
		elif [[ $OUTPUT == "-mem" ]]; then
			lsof -p $PID | grep 'mem' | awk '{print $7}' | sort -k2 -n
		else
			echo "Invalid output type $OUTPUT"
		fi
	fi
}

# =================================================================================================
# -- get-pids
# =================================================================================================
help_linux[get-pids]='Get all child pids for a process'
get-pids () {
	local PID=$1
	if [[ -z $PID ]]; then
		echo "Usage: get-pids <pid>"
		return 1
	else
		pstree -p ${PID} | grep -o '([0-9]\+)' | grep -o '[0-9]\+' 
	fi
}


# =================================================================================================
# -- sum-mem
# =================================================================================================
help_linux[sum-mem]='Sum memory usage of a process and its child processes'
sum-mem () {
	local PARENT_PID=$1
	local TOTAL_MEMORY=0 PID_MEMORY_USAGE
	if [[ -z $PARENT_PID ]]; then
		echo "Usage: sum-mem <parent_pid>"
		return 1
	fi
	# get pid process name
	PARENT_NAME=$(cat /proc/${PARENT_PID}/comm)
	_loading "Getting total memory usage for $PARENT_PID ($PARENT_NAME) and all child processes"

	# Get all child PIDs, get-pids is newlined add to array	
	_loading2 "Getting all child PIDs for $PARENT_PID"
	local ALL_PIDS=($(get-pids $PARENT_PID))
	
	# Iterate over each PID and sum their memory usage
	for PID in $ALL_PIDS; do
		# get process name
		local PID_NAME=$(cat /proc/${PID}/comm)
		echo -n $(_loading3 "Getting memory for $PID/$PID_NAME")
		# Get memory usage for PID, output is new line separated, add all up
		local PID_MEMORY_USAGE=$(lsof-mem $PID -mem | awk '{s+=$1} END {print s}')
		local TOTAL_MEMORY=$(( TOTAL_MEMORY + PID_MEMORY_USAGE))
		echo ".. $PID_MEMORY_USAGE bytes / $(( PID_MEMORY_USAGE / 1024 / 1024 )) MB"
	done

	_loading "Done collecting memory usage"
	_notice "Total memory usage: $TOTAL_MEMORY bytes"
	_notice "Total memory usage in from Bytes to MB: $(( TOTAL_MEMORY / 1024 / 1024 )) MB"
}

# =================================================================================================
# -- compress
# =================================================================================================
help_linux[compress]='Compress a file or folder'
function compress () {
	local DATA=$1
	local LOCATION="$HOME"
	# Create date for archive that is unique
	local DATE=$(date +%Y-%m-%d-%H-%M-%S)

	if [[ -z $DATA ]]; then
		echo "Usage: compress <file|folder>"
		return 1
	fi

	# Check if exists
	if [[ ! -e $DATA ]]; then
		_error "File or folder $DATA doesn't exist"
		return 1
	fi

	# Check if file or folder
    if [[ -f $DATA ]]; then
        # File
        # Create name that doesn't break, remove special chars etc
        FILENAME="${DATA%.*}-$DATE"
        _loading "Compressing file $DATA"
        _debug "tar -czvf ${LOCATION}/${FILENAME}.tar.gz ${DATA}"
        TAR="tar -czvf ${LOCATION}/${FILENAME}.tar.gz ${DATA}"
		_loading3 "Running: $TAR"
		eval $TAR
	elif [[ -d $DATA ]]; then
		# Folder
		# Create name with underscores related to path, skip first /
		FILENAME="$(echo $DATA | sed 's|^/||; s|/|_|g')-$DATE"
		_loading "Compressing folder ${DATA}"
		TAR="tar -czvf ${LOCATION}/${FILENAME}.tar.gz ${DATA}"
		_loading3 "Running: $TAR"
		eval $TAR
		
	else
		_error "Unknown file type"
		return 1
	fi
}

# =================================================================================================
# -- geekbench-run
# =================================================================================================
help_linux[geekbench-run]='Run geekbench'
geekbench-run () {
	# Download geekbench
	_loading "Downloading geekbench"
	DOWNLOAD_URL=$(wget -qO- https://www.geekbench.com/download/linux/ | sed -n "s/.*URL=\([^']*\).*/\1/p")
	wget -O /tmp/Geekbench-6.3.0-Linux.tar.gz "$DOWNLOAD_URL"

	# Extract geekbench
	_loading "Extracting geekbench"
	tar -xvf /tmp/Geekbench-6.3.0-Linux.tar.gz -C /tmp

	# Run geekbench
	_loading "Running geekbench"
	/tmp/Geekbench-6.3.0-Linux/geekbench_x86_64
}

# =================================================================================================
# -- geekbench-run-oneliner
# =================================================================================================
help_linux[geekbench-install]='Print out oneliner to download, and run geekbench'
geekbench-install () {
    echo 'cd /tmp && wget -O Geekbench.tar.gz "$(wget -qO- https://www.geekbench.com/download/linux/ | sed -n "s/.*URL=\([^'\'']*\).*/\1/p")" && tar -xzf Geekbench.tar.gz && ./Geekbench-6.3.0-Linux/geekbench6'
}