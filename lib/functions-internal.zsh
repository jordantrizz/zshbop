#!/usr/bin/env zsh
# =================================================================================================
# -- functions-internal.zsh -- Core functions for scripts
# =================================================================================================
_debug_load

# ===============================================
# -- Internal Functions
# ===============================================

# -- Default
_echo () { echo "$@" }
_success () { echo "$fg[green] * $@ ${RSC}" }
_noticebg () { echo "$bg[magenta]$fg[white] * $@ ${RSC}" }
_notice () { echo "$fg[magenta] * $@ ${RSC}" }
_warning () { echo "$fg[yellow] * $@ ${RSC}" }
# -- Banners
_banner_red () { echo "$bg[red]$fg[white]${@}${RSC}" }
_banner_green () { echo "$bg[green]$fg[white]${@}${RSC}" }
_banner_yellow () { echo "$bg[yellow]$fg[black]${@}${RSC}" }
_banner_grey () { echo "$bg[bright-grey]$fg[black]${@}${RSC}" }
# -- loading
_loading () { [[ $QUIET == 0 ]] && { echo "$bg[yellow]$fg[black] * ${@}${RSC}" | tee >(sed 's/^/[LOAD] /' >> ${ZB_LOG}); } }
_loading2 () { [[ $QUIET == 0 ]] && { echo "$bg[bright-grey]$fg[black] ** ${@}${RSC}" | tee >(sed 's/^/[LOAD] /' >> ${ZB_LOG}); } }
_loading2b () { [[ $QUIET == 0 ]] && { echo "$fg[bright-white] ** ${@}${RSC}" | tee >(sed 's/^/[LOAD] /' >> ${ZB_LOG}); } }
_loading3 () { [[ $QUIET == 0 ]] && { echo "$fg[bright-grey] *** ${@}${RSC}" | tee >(sed 's/^/[LOAD] /' >> ${ZB_LOG}); } }
_loading3_log () { echo "[LOAD] *** ${@} >> ${ZB_LOG}" }
_loading3b () { echo "$fg[bright-grey] ${@}${RSC}" | tee >(sed 's/^/[LOAD] /' >> ${ZB_LOG})}
_loading4 () { [[ $QUIET == 0 ]] && { echo "$fg[bright-grey] **** ${@}${RSC}" | tee >(sed 's/^/[LOAD] /' >> ${ZB_LOG}); } }
alias _loading_grey=_loading2
# -- dividers
_divider_white () { echo "$fg[black]$bg[white]                 $@               ${RSC}" }
_divider_grey () { echo "$bg[bright-grey]                 $@               ${RSC}" }
_divider_dash () { echo "$fg[bright-grey]-----------------$@---------------${RSC}" }

# -- Text Colors
_grey () { echo "$bg[bright-gray]$fg[black] $@ ${RSC}" }
_yellow () { echo "$fg[yellow]$@${RSC}" }
_red () { echo "$fg[red]$@${RSC}" }
_green () { echo "$fg[green]$@${RSC}" }
_blue () { echo "$fg[blue]$@${RSC}" }
_magenta () { echo "$fg[magenta]$@${RSC}" }
_cyan () { echo "$fg[cyan]$@${RSC}" }
_white () { echo "$fg[white]$@${RSC}" }
# -- Text Colors Bright
_bright_grey () { echo "$fg[bright-gray]$@${RSC}" }
_bright_yellow () { echo "$fg[yellow]$@${RSC}" }
_bright_red () { echo "$fg[red]$@${RSC}" }
_bright_green () { echo "$fg[green]$@${RSC}" }
_bright_blue () { echo "$fg[blue]$@${RSC}" }
_bright_magenta () { echo "$fg[magenta]$@${RSC}" }
_bright_cyan () { echo "$fg[cyan]$@${RSC}" }
_bright_white () { echo "$fg[white]$@${RSC}" }

RSC=$reset_color # To replace $reset_color :)
RED_BG="$fg[white]$bg[red]"
GREEN_BG="$fg[white]$bg[green]"

# -- Used for formatting function to print out all formatting
COLOR_FUNCTIONS=(_error _warning _success _noticebg _banner_red _banner_green _banner_grey _loading _loading2 _loading3 _loading4 _grey _divider_white _divider_grey _divider_dash)
COLOR_NAMES=(black red green yellow blue magenta cyan white bright-black bright-red bright-green bright-yellow bright-blue bright-magenta bright-cyan bright-white bright-grey)
COLOR_VARS=(RED_BG GREEN_BG)

# -- colors-print
help_int[colors-print]='Print all colors'
function colors-print () {
  for k in ${(k)COLOR_NAMES}; do
    #if [[ ! $k =~ ^(fg|bg|[[:digit:]]{1,3}|no-|none|normal|italic|underline|reverse|bold|conceal|faint|default|blink) ]]; then
        echo "${k}: ${fg[$k]} Foreground ${RSC} - ${bg[$k]}Background${RSC}"                      
  done

  for var in ${(k)COLOR_VARS}; do
    echo "${var}: ${(P)var}${var}${RSC}"
  done
}

# =========================================================
# -- _require_pkg ($package) ($install)
# --
# -- Check to see if command exists and if not install
# =========================================================
help_int[_require_pkg]='Check if command exists and if not install using package manager'
function _require_pkg () {
    local REQUIRE_PKG=$1 CHECK_PKG PKG_MANAGER PKG_INSTALL PACKAGE_INSTALLED INSTALL_PKG="${2:-1}"    
    _debug_all
    _debugf "Running _requires_pkg on $REQUIRE_PKG"    

    _package_manager
    
    for PKG in ${REQUIRE_PKG[@]}; do
        _debugf "Processing PKG: ${PKG} - ${PKG_MANAGER}"
        if [[ -x $(command -v $PKG) ]]; then
            _debugf "$PKG is installed as command";            
            continue
        fi
        PACKAGE_INSTALLED=$(eval $PKG_INSTALLED_CHECK $PKG 2> /dev/null)        
        if [[ $? == "0" ]]; then
            _debugf "$PKG is installed as package";            
            continue
        fi

        _debugf "$PKG not installed";                    
        PKG_INSTALL=($PKG)
    done

    if [[ -z $PKG_INSTALL ]]; then
        _debugf "All packages installed already"
        return 0
    fi

    if [[ $INSTALL_PKG == "1" ]]; then
        CMD_RUN="sudo $PKG_MANAGER $PKG_INSTALL"
        _debugf "Running - $CMD_RUN"
        eval $CMD_RUN
    else
        _debugf "Instructed not to install packages"
        echo "$PKG_INSTALL"
    fi
}

# =========================================================
# -- _requires_cmd ($command)
# --
# -- Check to see if $command is installed
# =========================================================
help_int[_requires_cmd]='Check to see if $command is installed'
_requires_cmd () {
    _debug_all
    _debugf "Running _requires on $1"
    _debugf "array: ${(P)${array_name}}"

    local array_name=$1
    CMD=""

    for CMD in ${(P)${array_name}}; do
        if (( $+commands[$CMD] )); then
        _debugf $(which $CMD)
            _debugf "$CMD is installed";
            REQUIRES_CMD=0
            return 0
        else
            _debugf "$CMD not installed";
            REQUIRES_CMD=1
            return 1
        fi
    done
}

# =========================================================
# -- _package_manager
# =========================================================
help_int[_package_manager]='Get package manager'
function _package_manager () {
    if [[ $(which apt-get) ]]; then
        _debugf "Using apt-get"
        PKG_MANAGER="apt-get install -y --no-install-recommends"
        PKG_INSTALLED_CHECK="dpkg-query -l"
        PKG_INSTALLABLE_CHECK="apt-cache show"
    elif [[ $(which yum) ]]; then
        _debugf "Using yum"
        PKG_MANAGER="yum"
    elif [[ $(which brew) ]]; then
        _debugf "Using brew"
        PKG_MANAGER="brew"
    elif [[ $(which ports) ]]; then
        _debugf "Using ports"
        PKG_MANAGER="ports"
    else
        _debugf "No package manager found"
        return 1
    fi    
}

# =========================================================
# -- _package_installable
# =========================================================
help_int[_package_installable]='Check if package is installable'
function _package_installable () {
    local PACKAGE=$1
    _debug_all
    _debugf "Checking if $PACKAGE is installable"
    if apt-cache show $PACKAGE >> /dev/null; then
        _debugf "$PACKAGE is installable"
        return 0
    else
        _debugf "$PACKAGE not installable"
        return 1
    fi
}

# =========================================================
# -- _package_installed
# =========================================================
help_int[_package_installed]='Check if package is installed'
function _package_installed () {
    local PACKAGE=$1
    _debug_all
    _debugf "Checking if $PACKAGE is installed"
    if dpkg-query -l $PACKAGE >> /dev/null; then
        _debugf "$PACKAGE is installed"
        return 0
    else
        _debugf "$PACKAGE not installed"
        return 1
    fi
}

# =========================================================
# -- _cmd_exists
# --
# -- Returns 0 if command exists or 1 if command doesn't exist
# =========================================================
help_int[_cmd_exists]="Returns 0 if command exists or 1 if command doesn't exist, will never output data"
function _cmd_exists () {
    CMD_EXISTS=""
    CMD="$1"

    # Check if command exists
    if command -v ${CMD} >> /dev/null; then
        _debugf "$CMD is installed";
        CMD_EXISTS="0"
    else
        _debugf "$CMD not installed";    
        CMD_EXISTS="1"
    fi

    # Check if alias exists
    return $CMD_EXISTS
}

# =========================================================
# -- checkroot()
# --
# -- checkroot - check if running as root
# =========================================================
help_int[_checkroot]="Check if running as root"
_checkroot () {     
    _debug_all    
    if [[ $EUID -ne 0 ]]; then        
        zb_logger "WARNING" 0 "Requires root...exiting - $funcstack"
        return 1
    else
        _debugf "Running as root"
        return 0
    fi
}

# =========================================================
# -- _if_marray - if in array.
# -- _if_marray "$NEEDLE" $HAYSTACK[@] TEST
# -- must use quotes, second argument is array without $
# =========================================================
help_int[_if_marray]="Check if value is in array"
_if_marray () {
    local NEEDLE=$1 HAYSTACK=$2
    MARRAY_VALID=1
    _debugf "$funcstack[1] - find value = $NEEDLE in array = $HAYSTACK"
    for value in ${(k)${(P)HAYSTACK[@]}}; do
            _debugf "$funcstack[2] - array=$HAYSTACK \$value = $value"
            if [[ $value == "$NEEDLE" ]]; then
                    _debugf "$funcstack[1] - array $HAYSTACK does contain $VALUE"
                    MARRAY_VALID="0"
            else
                    _debugf "$funcstack[1] - array $HAYSTACK doesn't contain $VALUE"
            fi
    done
    _debugf "MARRAY_VALID = $MARRAY_VALID"
    if [[ MARRAY_VALID == "1" ]] &&  return 1 || return 0
}

# =========================================================
# -- _inarray - if in array.
# -- _inarray $NEEDLE $DEBUG_OUTPUT "$HAYSTACK[@]""
# -- returns - 0 if in array, 1 if not in array
# --
# -- Example: if _inarray $feature 0 "${FEATURE_ERROR[@]}"; then
# =========================================================
help_int[_inarray]="Check if value is in array"
_inarray () {    
    local NEEDLE=$1 DEBUG_OUTPUT=$2 HAYSTACK=()
    shift;shift
    HAYSTACK=(${*})
    MARRAY_VALID=1
    [[ $DEBUG_OUTPUT == "1" ]] && DEBUGF="1"
    _debugf "$funcstack[1] - find \$VALUE = $NEEDLE in array = ${HAYSTACK[@]}"
    for VALUE in "${HAYSTACK[@]}"; do
        if [[ $VALUE == "$NEEDLE" ]]; then
                _debugf "$funcstack[1] - \$VALUE = $VALUE \$NEEDLE = $NEEDLE is in array = ${HAYSTACK[@]} !!!"
                MARRAY_VALID="0"
        else
                _debugf "$funcstack[1] - \$VALUE = $VALUE \$NEEDLE = $NEEDLE is not in array = ${HAYSTACK[@]}"            
        fi
    done
    _debugf "MARRAY_VALID = $MARRAY_VALID"
    [[ $DEBUG_OUTPUT == "1" ]] && DEBUGF="0"
    [[ $MARRAY_VALID == "0" ]] && return 0 
    [[ $MARRAY_VALID == "1" ]] && return 1
}

# --------------------------------
# -- _pipe_separate
# --
# -- Separate piped output into columns after third item
# --------------------------------
help_int[_pipe_separate]='Separate piped output into columns after third item or $1 items'
function _pipe_separate() {
    local -a lines=("${(f)$(cat)}")
    local -i count=0
    [[ ${1} ]] && local ITEMS=$1 || local ITEMS=3

    for line in "${lines[@]}"; do
        if (( count < ${ITEMS} )); then
        printf "%s | " "$line"
        (( count++ ))
        else
        printf "%s\n" "$line"
        count=0
        fi
    done
    echo ""
}
# =========================================================
# _detect_host_type
# =========================================================
help_int[_detect_host_type]="Detect if host is physical or virtual"
_detect_host_type() {
  local dmi_output
  dmi_output=$(sudo dmidecode -s system-product-name 2>/dev/null)

  if [[ -n $dmi_output ]]; then
    if [[ $dmi_output == Virtual* ]]; then
      echo "Virtual Machine"
    else
      echo "Physical Machine"
    fi
  else
    echo "Unable to determine"
  fi
}
# =========================================================
# -- _remove_last_line
# =========================================================
help_int[_remove_last_line]="Remove last line from string"
function _remove_last_line () {
    local STRING="${@%$'\n'*}"
    echo "$STRING"
}

# =========================================================
# -- os-alias - return alias if binary exists for os
# =========================================================
# TODO find other commands and use os-binary such as glint
help_int[os-alias]='Return alias if binary exists for os'
os-binary () {
    BINARY="$1"    

    _os_binary_usage () {
        echo "Usage: os-binary <binary>"
        echo "Example: os-binary glint"
        echo ""
        echo "Will create an alias for the binary if it exists for the current OS"
        echo ""
        echo "OS Matching"
        echo "Linux: linux_x86_64"
        echo "Mac: mac_x86_64"
        echo "Mac ARM: mac_arm64"
        echo "Mac Universal: mac"
        echo ""
        echo "Examples:"
        echo "os-binary glint"
        echo "  Possible binaries:"
        echo "    - glint_linux_x86_64"
        echo "    - glint_mac_x86_64"
        echo "    - glint_mac_arm64"
        echo "    - glint_mac"
        echo ""
        echo "MACHINE_OS: $MACHINE_OS"
        echo "MACHINE_OS2: $MACHINE_OS2"
        return 1
    }
    if [[ -z $BINARY ]]; then
        _debugf "No binary specified"
        _os_binary_usage
        return 1
    fi

    local OS_BINARY_TAG=""
	unset LC_CHECK NULL OS_BINARY
	_debugf "Running $MACHINE_OS"
	
	if [[ $MACHINE_OS == "linux" ]]; then
		_debugf "Detected OS linux"
		OS_BINARY_TAG="linux_x86_64"
	elif [[ $MACHINE_OS == "mac" ]]; then
        if [[ $MACHINE_OS2 = "mac-arm" ]]; then
            _debugf "Detected OS mac arm64"
            OS_BINARY_TAG="mac_arm64"
        else
            _debugf "Detected OS mac x86_64"
            OS_BINARY_TAG="mac_x86_64"
        fi
	else
		_debugf "Can't detect OS \$MACHINE_OS = $MACHINE_OS"
		_error "No binary available for $BINARY on $MACHINE_OS"
		return 1
	fi	
	
	OS_BINARY="${BINARY}-${OS_BINARY_TAG}"
	_debugf "OS_BINARY: $OS_BINARY"	
	_cmd_exists ${OS_BINARY}
	
	if [[ $? == "1" ]]; then
        # Check if there is a general binary available
        OS_GENERIC_BINARY="${BINARY}-${MACHINE_OS}"
        _debugf "OS_GENERIC_BINARY: $OS_GENERIC_BINARY"
        _cmd_exists ${OS_GENERIC_BINARY}
        if [[ $? == "1" ]]; then
            _debugf "$OS_GENERIC_BINARY - general binary not installed"
            return 1
        fi
        _debugf "Using created alias ${BINARY}_${MACHINE_OS}"
        eval "function ${BINARY} () { ${OS_GENERIC_BINARY} \$@ }"
        eval "export ${(U)BINARY}_CMD=$OS_GENERIC_BINARY"
        return 0
	else
	    _debugf "Using created alias ${BINARY} ${OS_BINARY}"
	    eval "function ${BINARY} () { ${OS_BINARY} \$@ }"
        eval "export ${(U)BINARY}_CMD=$OS_BINARY"
	    return 0
	fi
}

# =========================================================
# -- faketty - run command in a fake tty
# =========================================================
help_int[faketty]='Run command in a fake tty'
faketty() {                       
    0</dev/null script --quiet --flush --return --command "$(printf "%q " "$@")" /dev/null
}
# =========================================================
# -- grepcidr3
# =========================================================
help_int[grepcidr3]='grepcidr3'
function _check_grepcidr3 () {
    if [[ $MACHINE_OS == "linux" ]]; then
        alias grepcidr3="grepcidr3_linux"
    fi

    if [[ $MACHINE_OS == "mac" ]]; then
        _cmd_exists grepcidr3
        if [[ $? == "1" ]]; then
            echo "test"
            function grepcidr3 () { _error "grepcidr3 not installed, install using mac ports"; }
            return 1
        fi
    fi
}
_check_grepcidr3

# =========================================================
# -- remove ansi color
# =========================================================
help_int[remove-ansi]='Remove ansi color'
function remove-ansi () {
  #sed -E "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"
  sed -e 's/\x1b\[[0-9;]*m//g'
}


# --------------------------------------------------
# -- _get-os-install-date $ECHO_OUTPUT
# --------------------------------------------------
help_int[_get-os-install-date]='Get and set OS_INSTALL variables'
function _get-os-install-date {
	[[ -n $1 ]] && ECHO_OUTPUT="$1" || ECHO_OUTPUT="1"
	local OS_INSTALL_ROOT_DEVICE=$(df -h / | awk 'NR==2 {print $1}')
	# -- Method 1
	OS_INSTALL_DATE=$(\ls -lct --time-style=full-iso / | tail -1 | awk '{print $6, $7}')
    OS_INSTALL_METHOD="Linux ls -lct --time-style=full-iso /"

	# -- Convert date to MM-DD-YYYY
	OS_INSTALL_DATE=$(echo $OS_INSTALL_DATE | awk '{print $1}' | awk -F- '{print $2"-"$3"-"$1}')	
	
	# -- Method 2	
    _checkroot
	if [[ $? == "1" ]]; then
		OS_INSTALL_METHOD2="Root access required to run INSTALL_METHOD2"
		export OS_INSTALL_METHOD2
	else
		[[ -z "$OS_INSTALL_ROOT_DEVICE" ]] && { _error "Root device not found.";export OS_INSTALL_ROOT_DEVICE="Can't find root device"; return 1 }
		OS_INSTALL_METHOD2="dumpe2fs -h $OS_INSTALL_ROOT_DEVICE"
    
		# Use dumpe2fs to get the filesystem creation time
		local OS_INSTALL_DATE2=$(sudo dumpe2fs -h $OS_INSTALL_ROOT_DEVICE 2>/dev/null | grep 'Filesystem created:' | cut -d ':' -f2-)

		# Check if dumpe2fs was successful
		if [[ -z "$OS_INSTALL_DATE2" ]]; then
			echo "Could not determine filesystem creation time for $OS_INSTALL_ROOT_DEVICE."
			return 2
		fi

		# -- Convert date Wed Apr 10 12:35:05 2019 to MM-DD-YYYY	
		OS_INSTALL_DATE2=$(echo $OS_INSTALL_DATE2 | awk '{print $2"-"$3"-"$5}' | date -f - +%m-%d-%Y)		
	fi

	if [[ $ECHO_OUTPUT == "1" ]]; then
		_loading "Getting OS install date..."
		echo "\$INSTALL_DATE: $OS_INSTALL_DATE | \$INSTALL_METHOD: $OS_INSTALL_METHOD"
		echo "\$INSTALL_DATE2: $OS_INSTALL_DATE2 | \$INSTALL_ROOT_DEVICE: $OS_INSTALL_ROOT_DEVICE: | \$OS_INSTALL_METHOD2: $OS_INSTALL_METHOD2"	
	fi

	
	export OS_INSTALL_DATE
	export OS_INSTALL_METHOD
	export OS_INSTALL_DATE2
	export OS_INSTALL_METHOD2
	export OS_INSTALL_ROOT_DEVICE

}

# =========================================================
# -- _seconds_to_human - convert seconds to human readable
# =========================================================
function _seconds_to_human () {
    local SECONDS=$1

    # Convert to years, months, days, hours, minutes, seconds    
    local YEARS=$((SECONDS / 31536000))
    local SECONDS=$((SECONDS % 31536000))
    local MONTHS=$((SECONDS / 2592000))
    local SECONDS=$((SECONDS % 2592000))
    local DAYS=$((SECONDS / 86400))
    local SECONDS=$((SECONDS % 86400))
    local HOURS=$((SECONDS / 3600))
    local SECONDS=$((SECONDS % 3600))
    local MINUTES=$((SECONDS / 60))
    local SECONDS=$((SECONDS % 60))

    # Output the human readable time, but don't print zeros if the previous value is zero
    local HR_TIME=""
    if [[ $YEARS -gt 0 ]]; then
        HR_TIME+="${YEARS}y "
    fi
    if [[ $MONTHS -gt 0 ]]; then
        HR_TIME+="${MONTHS}m "
    fi
    if [[ $DAYS -gt 0 ]]; then
        HR_TIME+="${DAYS}d "
    fi
    if [[ $HOURS -gt 0 ]]; then
        HR_TIME+="${HOURS}h "
    fi
    if [[ $MINUTES -gt 0 ]]; then
        HR_TIME+="${MINUTES}m "
    fi
    if [[ $SECONDS -gt 0 ]]; then
        HR_TIME+="${SECONDS}s"
    fi
    
    echo $HR_TIME
}

# =====================================
# -- _stderr - send message to stderr
# =====================================
help_int[_stderr]='Send message to stderr'
function _stderr () {
    echo "$@" >&2
}

# =====================================
# -- _validate_ip
# =====================================
help_int[_validate_ip]='Validate IP address'
function _validate_ip () {
    local IP=$1
    
    # Split the IP by dots
    local -a octets
    octets=(${(s:.:)IP})
    
    # Check if there are exactly 4 octets
    if [[ ${#octets} -ne 4 ]]; then
        _stderr "IP address must have exactly 4 octets"
        return 1
    fi

    # Check if each octet is a number between 0 and 255
    for octet in ${octets[@]}; do
        if ! [[ "$octet" =~ ^[0-9]+$ ]] || (( octet < 0 || octet > 255 )); then
            _stderr "Each octet must be a number between 0 and 254 - $octet"
            return 1
        fi
    done

    return 0
}
