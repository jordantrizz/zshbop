# =============================================================================
# -- Linux commands
# =============================================================================
_debug " -- Loading ${(%):-%N}"
help_files[linux]='Linux related commands'
typeset -gA help_linux

# =============================================================================
# -- swap-find - find what's using swap.
# ===============================================
help_linux[swap-find]='Find what processes are using swap.'
swap-find () {
	find /proc -maxdepth 2 -path "/proc/[0-9]*/status" -readable -exec awk -v FS=":" '{process[$1]=$2;sub(/^[ \t]+/,"",process[$1]);} END {if(process["VmSwap"] && process["VmSwap"] != "0 kB") printf "%10s %-30s %20s\n",process["Pid"],process["Name"],process["VmSwap"]}' '{}' \; | awk '{print $(NF-1),$0}' | sort -h | cut -d " " -f2-
}

# ===============================================
# -- dir-filecount
# ===============================================
help_linux[dir-filecount]='Count how many files are in each directory, recusively and report back a total.'
dir-filecount () {
	# - default to current directory
	local TARGET_DIR=${1:-"."}
		
	find -maxdepth 1 -type d | sort | while read -r dir; do n=$(find "$dir" -type f | wc -l); printf "%4d : %s\n" $n "$dir"; done
}

# ===============================================
# -- dir-dircount
# ===============================================
help_linux[dir-dircount]='Count how many directories are in each directory, recusively and report back a total.'
dir-dircount () {
	# - default to current directory	
	local TARGET_DIR=${1:-"."}
	_loading "Counting directories in $TARGET_DIR"

	if [[ ! -d $TARGET_DIR ]]; then
		_error "Directory $TARGET_DIR does not exist."
		return 1
	fi
	TARGET_DIR=$(realpath "$TARGET_DIR")
	_loading2 "Directory $TARGET_DIR found, counting directories..."

	find "$TARGET_DIR" -maxdepth 1 -type d | while read -r dir; do 
		# Skip the target directory itself
		if [[ "$dir" == "$TARGET_DIR" ]]; then
			continue
		fi
		
		# Get the full path
		local full_path=$(realpath "$dir")
		
		# Count only immediate subdirectories (depth 1)
		n=$(find "$dir" -maxdepth 1 -type d | tail -n +2 | wc -l)
		printf "%s   %d\n" "$(basename "$dir")" $n
	done
}

# ===============================================
# -- backup
# ===============================================
help_linux[backup]='Backup a folder in a tar file'
backup () {
	if [[ -z $1 ]]; then
		echo "Usage: backup <folder>"
		echo
		echo "Options:"
		echo "  -p <size>        - Split into multiple files of <count> MB each"
		echo
		echo "Examples:"
		echo "  backup /home/user/folder"
		echo "  backup -p 500 /home/user/folder"
		return
	fi
	
	# Parse options first
	zparseopts -D -E p:=PART_SIZE
	_debugf "PART_SIZE: $PART_SIZE"
	
	# Get the folder argument after parsing options
	local BACKUP_DIR=$1
	
	[[ ! -d $BACKUP_DIR ]] && { _error "Folder $BACKUP_DIR doesn't exist...exiting"; return 1 }
	
	if [[ -z $PART_SIZE ]]; then
		TAR_BACKUP_DATE=`date +%m-%d-%Y`
		_loading "Backing up folder $BACKUP_DIR to $BACKUP_DIR-${TAR_BACKUP_DATE}.tar"
		echo ""
		tar -cf $BACKUP_DIR-${TAR_BACKUP_DATE}.tar $BACKUP_DIR
		if [[ $? != 0 ]]; then
			_error "Error creating tar file"
			return 1
		else
			_success "Completed backup of $BACKUP_DIR to $BACKUP_DIR-${TAR_BACKUP_DATE}.tar"
		fi
	else
		# Extract the size value from the array
		local SIZE_VALUE=${PART_SIZE[2]}
		TAR_BACKUP_DATE=`date +%m-%d-%Y`
		_loading "Backing up folder $BACKUP_DIR to $BACKUP_DIR-${TAR_BACKUP_DATE}.tar and splitting into ${SIZE_VALUE} MB parts"
		echo ""
		_loading2 "Creating tar archive and splitting into parts..."
		
		# Use split with verbose output and monitor parts being created
		tar -cf - $BACKUP_DIR | split -b ${SIZE_VALUE}M - $BACKUP_DIR-${TAR_BACKUP_DATE}.tar.part- &
		TAR_PID=$!
		
		# Monitor the split process
		sleep 2
		while kill -0 $TAR_PID 2>/dev/null; do
			part_count=$(ls $BACKUP_DIR-${TAR_BACKUP_DATE}.tar.part-* 2>/dev/null | wc -l)
			if [[ $part_count -gt 0 ]]; then
				latest_part=$(ls -t $BACKUP_DIR-${TAR_BACKUP_DATE}.tar.part-* 2>/dev/null | head -1)
				if [[ -n $latest_part ]]; then
					part_size=$(du -h "$latest_part" 2>/dev/null | cut -f1)
					_loading3 "Created $part_count parts so far... Latest: $(basename "$latest_part") ($part_size)"
				fi
			fi
			sleep 3
		done
		
		wait $TAR_PID
		tar_exit_code=$?
		
		if [[ $tar_exit_code != 0 ]]; then
			_error "Error creating tar file"
			return 1
		else
			final_part_count=$(ls $BACKUP_DIR-${TAR_BACKUP_DATE}.tar.part-* 2>/dev/null | wc -l)
			_success "Completed backup of $BACKUP_DIR to $BACKUP_DIR-${TAR_BACKUP_DATE}.tar in $final_part_count parts of ${SIZE_VALUE} MB each"
			_loading2 "Part files created:"
			ls -lh $BACKUP_DIR-${TAR_BACKUP_DATE}.tar.part-*
		fi
	fi
}

# ===============================================
# -- ps2
# ===============================================
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

# ===============================================
# -- ps-cpu
# ===============================================
help_linux[ps-cpu]='Show top 5 CPU applications'
ps-cpu () {
    ps aux --sort -pcpu | head -5
}

# ===============================================
# -- ps-mem2
# ===============================================
help_linux[ps-mem2]='Show memory as human readable and sort'
function ps-mem2() {
    local sortbyfield="rss"
    local fsep="-o zzz:::zzz%% -o"
    local ps_cmd="\ps ax o user:16 $fsep pid $fsep pcpu $fsep pmem $fsep vsz $fsep rss $fsep tty $fsep stat $fsep lstart $fsep time:16 $fsep cmd --sort -$sortbyfield"
    local awk_cmd="awk 'function setprefix(num){{n_suffix=1; while(num > 1000 && n_suffix < suffixes_len) {num /= 1024; n_suffix++;}; num=int(100*num)/100suffixes[n_suffix]}; return num} BEGIN{suffixes_len=split(\"kB MB GB TB PB EB ZB\",suffixes);FS=\"zzz:::zzz%\";} NR>1 {\$5=setprefix(\$5);\$6=setprefix(\$6); }{ printf \"%-16s %6s %-5s %-5s %9s %9s %-8s %-8s %-25s %-18s %s\n\", \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11;}'"
    local cut_cmd="cut -c -250"
    eval "$ps_cmd | $awk_cmd | $cut_cmd"
}

# ===============================================
# -- ps-mem
# ===============================================
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

# ===============================================
# -- fork
# ===============================================
help_linux[fork]='Fork command into background'
fork () {
	(setsid "$@" &);
}
# ===============================================
# -- sysr
# ===============================================
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

# ===============================================
# -- syss
# ===============================================
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

# ===============================================
# -- sysrld
# ===============================================
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

# ===============================================
# -- usedspace
# ===============================================
help_linux[usedspace]='Show disk space and not count symlinks or tmpfs'
usedspace () {
	find / -maxdepth 1 -type d | xargs du -b --exclude=/proc --exclude=/dev --exclude=/run -h -d 1
}

# ===============================================
# -- check-diskspace
# ===============================================
help_linux[check-diskspace]="Check diskspace based on OS"
check-diskspace () {
	if [[ $MACHINE_OS == "linux" ]]; then
		linux-checkdiskspace
	else
		_error "check-diskspace not supported on $MACHINE_OS"
	fi
}

# ===============================================
# -- check_blockdevices
# ===============================================
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

# ===============================================
# -- check_diskspace
# ===============================================
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

# ===============================================
# -- speed-convert
# ===============================================
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

# ===============================================
# -- utc
# ===============================================
help_linux[utc]="Display UTC date and time"
function utc () {
	date -u
}

# ===============================================
# -- datetz
# ===============================================
help_linux[datetz]="Display specified timezone date and time"
datetz () {
	env TZ=":US/Pacific" date
	env TZ=":US/Central" date
	env TZ=":US/Eastern" date
	env TZ="UTC" date
}

# ===============================================
# -- swappiness
# ===============================================
help_linux[swappiness]="Display swappiness"
swappiness () { mem } # alias to mem

# ===============================================
# -- ubuntu-lts
# ===============================================
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

# ===============================================
# -- Screen sessions
# ===============================================
help_linux[screen-sessions]="Display screen sessions"
screen-sessions () {
	local SSESSIONS_OUTPUT SSESSIONS
	# -- Check if on WSL
	if [[ $MACHINE_OS2 == "wsl" ]]; then
		_loading3 "Detect wsl, running wsl-screen fix"
		wsl-screen-fix
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
        _warning "Screen not installed"
    fi
}

# ===============================================
# -- rename-ext
# ===============================================
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

# ===============================================
# -- add-path
# ===============================================

help_linux[add-path]='Add to $PATH'
add-path () {
	if [[ -z $1 ]]; then
		echo "Usage: add-path <path>"
		return 1
	else
		export PATH=$PATH:$@
	fi
}

# ===============================================
# -- paths - print out $PATH on new lines
# ===============================================
help_linux[paths]='print out \$PATH on new lines'
paths () {	
	_loading "Printing out \$PATH on new lines"
	GET_PATHS=$(echo $PATH | tr ":" "\n")
	echo "$GET_PATHS" | sort
	
	_loading "Printing out duplicates"
	# Only print out matches greater than 1
	echo "$GET_PATHS" | sort | uniq -c | awk '$1 > 1'

	# Get Total Paths
	_total_paths=$(echo $PATH | tr ":" "\n" | wc -l)
	_notice "Total paths: $_total_paths"
}

# ===============================================
# -- catvet
# ===============================================

help_linux[catvet]='Print out special formatting characters in a file or via pipe'
catvet () {
	echo "To print out the special formatting characters..."
	echo "echo 'testing\n' | cat -vet"
}

# ===============================================
# -- std-view
# ===============================================
help_linux[std-view]="Print stdout and stderr on command output"
function std-view() {
    if [[ -z $1 ]]; then
        echo "Usage: std-view <command>"
        return 1
    else
        # Use process substitution for cleaner handling of streams
        eval "$1 > >(sed 's/^/STDOUT: /') 2> >(sed 's/^/STDERR: /' >&2)"
    fi
}

# ===============================================
# -- get-os-install-date
# ===============================================
help_linux[get-os-install-date]='Get the date the OS was installed'
alias get-os-install-date="_get_os_install_date"

# ===============================================
# -- swappiness-set <size> - set swap size
# ===============================================
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

# ===============================================
# -- Reset Swap
# ===============================================
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

# ===============================================
# -- linux - list all linux flavours and versions with code names
# ===============================================
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


# ===============================================
# -- date override
# ===============================================
help_linux['date-more']='Show current date and C.UTF-8 date'
function date-more () {
    # Show current date
    echo "System: $(/bin/date)"
    echo "-------------------------------------"
    # Show C.UTF-8 date
    echo "C.UTF-8: $(LC_ALL=C.UTF-8 /bin/date)"
}


# =============================================================================
# -- lsof-mem
# =============================================================================
help_linux[lsof-mem]='List open file memory usage of a process'
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

# =============================================================================
# -- get-pids
# =============================================================================
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


# =============================================================================
# -- sum-mem
# =============================================================================
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
	_debug "All PIDS: $ALL_PIDS"
	
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

# =============================================================================
# -- compress
# =============================================================================
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

# ===============================================
# -- sstrace - strace a process
# ===============================================
help_linux[sstrace]='Strace a process'
sstrace () {
	_usage_sstrace () {
		echo "Usage: sstrace -n <process_name>|-u <username>|-p <pid>|[-o <file|stdout>]"
	}
	# Trap SIGINT (Ctrl + C) to print a message
    trap '_sstrace_exit $OUTPUT;' SIGINT

	_sstrace_exit () {
		echo "Strace interrupted by user - exiting - $@"	
		[[ $1 == "file" ]] && { sleep 1;_loading3 "File saved to $FILE" }
	}		

	_sstrace_pids () {
		local PIDS=("$@") STRACE_PIDS=()
		for PID in $PIDS; do
			STRACE_PIDS+=("-p $PID")
		done
		echo $STRACE_PIDS
	}
		
	local STRACE_ARG=()	
	local STRACE_OUTPUT=()
	local PID PROCESS_NAME PUSERNAME 
	local ARG_PID ARG_PROCESS_NAME ARG_PUSERNAME ARG_OUTPUT
	local PIDS FILE FILE_PATH DATE PIDS_SAME_LINE OUTPUT
	local MESSAGE
	local DATE=$(date +%Y-%m-%d-%H-%M-%S)
	local FILE_PATH="/tmp"
	local FILE="$FILE_PATH/sstrace-$PID-$DATE.log"
	
	
	zparseopts -D -E p:=ARG_PID n:=ARG_PROCESS_NAME u:=ARG_PUSERNAME o:=ARG_OUTPUT

	# Get the process name
	[[ -n $ARG_PID ]] && PID=$ARG_PID[2]
	[[ -n $ARG_PROCESS_NAME ]] && PROCESS_NAME=$ARG_PROCESS_NAME[2]
	[[ -n $ARG_PUSERNAME ]] && PUSERNAME=$ARG_PUSERNAME[2]
	[[ -n $ARG_OUTPUT ]] && OUTPUT=$ARG_OUTPUT[2] || OUTPUT="file"
	
	[[ $OUTPUT == "file" ]] && STRACE_OUTPUT+=(-o $FILE)

	_debugf "PID: $PID - PROCESS_NAME: $PROCESS_NAME - PUSERNAME: $PUSERNAME"
		
	# Check if strace is installed
	_cmd_exists strace
	if [[ $? == "1" ]]; then
		_error "strace not installed"
		return 1
	fi
	
	# Process name
	if [[ -n $PROCESS_NAME ]]; then
		_loading "Stracing process $PROCESS_NAME"
		PIDS=$(pgrep $PROCESS_NAME)	
		[[ -z $PIDS ]] && { _error "Process $PROCESS_NAME not found"; return 1; }
		
		MESSAGE="Stracing process $PROCESS_NAME"
	# PID
	elif [[ -n $PID ]]; then
		[[ -z $PID ]] && { _error "Process $PID not found"; return 1; }
		_loading "Stracing process with PID: $PID"
		PIDS=$(pgrep -P $PID)
		PIDS=($PID $PIDS)

		MESSAGE="Stracing process $PID"
	# PUSERNAME
	elif [[ -n $PUSERNAME ]]; then		
		_loading "Stracing process with username $PUSERNAME"		
		PIDS=$(pgrep -u $PUSERNAME)
		[[ -z $PIDS ]] && { _error "Process $PUSERNAME not found"; return 1; }
				
		MESSAGE="Stracing process $PUSERNAME"
	else
		_error "No process name or PID provided"
		_usage_sstrace
	fi

	PIDS_SAME_LINE=($(echo ${PIDS[@]} | tr '\n' ' '))	
	_loading2 "$MESSAGE with PIDs: $PIDS_SAME_LINE"
	STRACE_ARG=($(_sstrace_pids ${PIDS_SAME_LINE[@]}))
	_debugf "strace -f -s 40000 ${STRACE_OUTPUT[@]} ${STRACE_ARG[@]}"
	eval $(strace -f -s 40000 ${STRACE_OUTPUT[@]} ${STRACE_ARG[@]})
}


# ===============================================
# -- smartctl-all-disks
# ===============================================
help_linux[smartctl-all-disks]='Run smartctl on all disks'
smartctl-all-disks () {	
	_smartctl-all-disks-usage () {
		echo "Usage: smartctl-all-disks [option]"
		echo "  -all-details"
		echo "  -errors-only"
		echo "  -errors-serial"
		echo "  -h, --help"
	}

	local ALL_DETAILS ERRORS_ONLY ERRORS_SERIAL HELP SMARTCTL_OUTPUT

	zparseopts -D -E h:=HELP all-details=ALL_DETAILS errors-only=ERRORS_ONLY errors-serial=ERRORS_SERIAL
	[[ -n $HELP ]] && { _smartctl-all-disks-usage; return 1; }

	# Check if smartctl is installed
	_cmd_exists smartctl
	if [[ $? == "1" ]]; then
		_error "smartctl not installed"
		return 1
	fi

	# Get a list of all block devices
	DEVICES=($(lsblk -n -d -o NAME | grep -v "^loop" | grep -v "^sr" | grep -v "^ram" | grep -v "^zram" | grep -v "^zd"))
	if [[ -n $ALL_DETAILS ]]; then
		_loading "Running smartctl on all disks"
		for i in $DEVICES; do
			echo "Disk $i"
			smartctl -i -A /dev/$i
		done
	elif [[ -n $ERRORS_SERIAL ]]; then
		_loading "Running smartctl on all disks, showing errors and serial only."
		for i in $DEVICES; do
			_loading2 "Disk $i"
			SMARTCTL_OUTPUT=$(smartctl -i -A /dev/$i)
			echo $SMARTCTL_OUTPUT | egrep -E -i "Serial Number|Device Model|Firmware Version|User Capacity|TRIM Command|SMART support is"
			echo $SMARTCTL_OUTPUT | egrep -E -i "^  "5"|^"197"|^"198"|"FAILING_NOW""			
		done
	elif [[ -n $ERRORS_ONLY ]]; then
		_loading "Running smartctl on all disks, showing errors only."
		for i in $DEVICES; do
			echo "Disk $i - smartctl --quietmode=errorsonly -i -A /dev/$i"
			smartctl --quietmode=errorsonly -i -A /dev/$i
		done
	else
		_smartctl-all-disks-usage
	fi
}

# ===============================================
# -- whatprovides - find what package provides a command
# ===============================================
help_linux[whatprovides]='Find what package provides a specific command'
function whatprovides() {
    if [[ -z $1 ]]; then
        _error "Usage: whatprovides <command>"
        return 1
    fi

	local COMMAND_NAME=$1
	_loading "Searching for '$COMMAND_NAME'..."
    _loading2 "1. Checking if $COMMAND_NAME is installed"
    # First check if the command is already installed
	
	_cmd_exists $COMMAND_NAME
	if [[ $? == "0" ]]; then
		_success "Command $COMMAND_NAME is already installed"		
	else
		_error "Command $COMMAND_NAME is not installed"
	fi

	# Try whatprovides-db first
	_loading2 "2. Checking whatprovides-db for $COMMAND_NAME"
	whatprovides-db $COMMAND_NAME
	if [[ $? == "0" ]]; then
		_success "Command $COMMAND_NAME found in whatprovides-db"
		_loading3 "Package: ${whatprovides_db[$COMMAND_NAME]}"		
	else
		_error "Command $COMMAND_NAME not found in whatprovides-db, trying apt-file"
	fi
    
	_loading2 "3. Searching for '$COMMAND_NAME' using apt-file..."
	    # If command is not installed, we need apt-file
	_cmd_exists apt-file
	if [[ $? == "1" ]]; then
		_error "apt-file is not installed"
		_loading3 "Installing apt-file..."3
		sudo apt-get install apt-file
		if [[ $? == "0" ]]; then
			_success "apt-file installed"
		else
			_error "apt-file failed to install"
			return 1
		fi
	fi

	_loading3 "apt-file is already installed"
	_loading3 "Updating apt-file..."
	sudo apt-file update
	apt-file search "$COMMAND_NAME"
}

# ===============================================
# -- whatprovides-db - A database of whatprovides for quicker lookups
# ===============================================
help_linux[whatprovides-db]='A database of whatprovides for quicker lookups'
function whatprovides-db () {
	# Database of common commands and their packages
	typeset -gA whatprovides_db
	# Add commands to the database
	whatprovides_db[netstat]="net-tools"
	whatprovides_db[ss]="iproute2"
	whatprovides_db[ifconfig]="net-tools"
	whatprovides_db[traceroute]="traceroute"

	if [[ -z $1 ]]; then
		_error "Usage: whatprovides-db <command>"
		return 1
	fi

	local COMMAND_NAME=$1
	_loading "Searching for packages that provide '$COMMAND_NAME'..."

	# Check if the command is in the database
	if [[ -n $whatprovides_db[$COMMAND_NAME] ]]; then
		_loading2 "Command $COMMAND_NAME is in the database"
		_loading3 "Package: $whatprovides_db[$COMMAND_NAME]"
	else
		_loading2 "Command $COMMAND_NAME is not in the database"
	fi
	
}

# ===============================================
# -- last-boots
# ===============================================
help_linux[last-boot]="Get last boot times"
function last-boots () {
    _loading "Running journalctl --list-boots"
    journalctl --list-boots
}

# ===============================================
# -- journalctl-cron
# ===============================================
help_linux[journalctl-cron]="Get cron logs last 48 hours"
function journalctl-cron () {
    _loading "Running journalctl -u cron.service --since '48 hours ago'"
    journalctl -u cron.service --since '48 hours ago'
}

# ===============================================
# -- syslog-cron
# ===============================================
help_linux[syslog-cron]="Get cron logs from syslog"
function syslog-cron () {
	_loading "Running grep CRON /var/log/syslog"
	grep -i 'CRON' /var/log/syslog
}


# ===============================================
# -- oom-check
# ===============================================
help_linux[oom-check]='Check for OOM killer running, list all oom killed processes with timestamps'
oom-check () {
	# Check if journalctl is installed
	_cmd_exists journalctl
	if [[ $? == 0 ]]; then
		_loading "Running journalctl -k | grep -i 'oom'"
		journalctl -k | grep -i 'Out of memory: Killed process'
	elif [[ -f /var/log/syslog ]]; then
		_loading "Running grep -i 'Out of memory: Killed process' /var/log/syslog"
		grep -i 'Out of memory: Killed process' /var/log/syslog
		return 1
	fi
}

# ===============================================
# -- ps-top
# ===============================================
help_linux[ps-top]='Show processes using ps and refresh a configurable amount of time'
ps-top() {
  	# Help flag
	_ps-top-usage () {
		
		echo "Usage: ps-top [interval] [cpu|mem] [topN]"
		echo "  interval: Time in seconds to refresh (default: 2)"
		echo "  cpu|mem: Sort by CPU usage or memory usage (default: cpu)"		
		echo "  topN: Show top N processes (default: 0, show all)"
		echo "  -h, --help: Show this help message"
		echo "  Example: ps-top 2 cpu 10"		
	}

	if [[ $1 == "-h" || $1 == "--help" ]]; then
		_ps-top-usage
		return 0
	fi

	local INTERVAL="${1:-2}"
	local SORTFIELD="${2:-cpu}"
	local TOPN="${3:-0}"
	local SORTCOL TOPCMD CMD

	case "$SORTFIELD" in
		cpu) SORTCOL=3 ;;
		mem) SORTCOL=4 ;;
		*)
		echo "Invalid sort field: '$SORTFIELD' (use cpu or mem)"
		return 1
		;;
	esac

	if (( TOPN > 0 )); then
		TOPCMD=" | head -n $TOPN"
	else
		TOPCMD=""
	fi

	CMD="ps -eo user:32,pid,%cpu,%mem,cmd --forest \
		| { read -r header; echo \"\$header\"; tail -n +2 \
			| sort -nrk${SORTCOL},${SORTCOL}${TOPCMD}; }"

	watch -n "$INTERVAL" "$CMD"
}

# ===============================================
# -- unix-epoch-ms
# ===============================================
help_linux[unix-epoch-ms]='Convert unix epoch in miliseconds to human readable date'
unix-epoch-ms () {
     if [[ -z $1 ]]; then
          echo "Usage: unix-epoch-ms <epoch-in-ms>"
          return 1
     fi
     local epoch_ms=$1
     local epoch_sec=$((epoch_ms / 1000))
     local date_str=$(date -d "@$epoch_sec" +"%Y-%m-%d %H:%M:%S")
     echo "Epoch in ms: $epoch_ms"
     echo "Converted date: $date_str"
}
