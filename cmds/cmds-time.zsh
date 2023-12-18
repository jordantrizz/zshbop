# --
# time commands
#
# Example help: help_time[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_time

# What help file is this?
help_files[time]='Time based commands'

# ==============================================================================
# -- tzc
# ==============================================================================
help_time[tzc]='Convert time based on timezones'
function tzc () {
    function _tzc_usage () {
        echo "Usage: tzc <YYYY-MM-DD> <HH:MM:SS> <source_timezone> <target_timezone>"
		echo ""
		echo "EST = EST5EDT"
		echo "CST = CST6EDT"
    }

	# Default Linux date %a %d %b %Y %r %Z = Fri 17 Mar 2023 11:05:40 AM EDT
	# Check if the required command 'date' is available
	if ! command -v date &> /dev/null; then
		echo "The 'date' command is required but not found. Please install it and try again."
		return 1
	fi

	# Check if the required number of arguments is passed
	if [ $# -eq 3 ]; then
        INPUT_D="${1}"
        INPUT_T="${2}"
        INPUT_DATE="${1} ${2}"
        STZ="${3}"
        # Get system timezone
        TTZ=$(date +%Z)
    elif [ $# -eq 4 ]; then
        INPUT_D="${1}"
        INPUT_T="${2}"
        INPUT_DATE="${1} ${2}"
        STZ="${3}"
        TTZ="${4}"
    else
        _tzc_usage
        return 1
    fi


    MSG="Converting ${INPUT_DATE} from ${STZ} to ${TTZ}"
    EST="EST"
    CST="CST"
	setopt extendedglob
    if [[ $STZ == (#i)"$EST" ]]; then STZ="EST5EDT"; MSG+=" S+DST"; fi
    if [[ $TTZ == (#i)"$EST" ]]; then TTZ="EST5EDT"; MSG+=" T+DST"; fi
    if [[ $STZ == (#i)"$CST" ]]; then STZ="CST6CDT"; MSG+=" S+DST"; fi
    if [[ $TTZ == (#i)"$CST" ]]; then TTZ="CST6CDT"; MSG+=" T+DST"; fi

    echo "$MSG"

    # Convert date and time to the target time zone
    converted_date=$(TZ="${TTZ}" date -d"TZ=\"${STZ}\" ${INPUT_DATE}")

    if [ $? -ne 0 ]; then
        echo "Error: Conversion failed. Please check your input and try again."
        return 1
    fi

    echo "Converted Time: $converted_date"
}