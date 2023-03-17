# --
# time commands
#
# Example help: help_time[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# - Init help array
typeset -gA help_time

# -- tzc
help_time[tzc]='Convert time'
tzc () {
	# Default Linux date %a %d %b %Y %r %Z = Fri 17 Mar 2023 11:05:40 AM EDT
	# Check if the required command 'date' is available
	if ! command -v date &> /dev/null; then
		echo "The 'date' command is required but not found. Please install it and try again."
		exit 1
	fi

	# Check if the required number of arguments is passed
	if [ $# -ne 3 ]; then
		echo "Usage: ./tzc.sh <YYYY-MM-DD HH:MM:SS> <source_timezone> target_timezone"
		echo ""
		echo "EST = EST5EDT"
		echo "CST = CST6EDT"
		exit 1
	fi

    INPUT_DATE="${1}"
    STZ="${2}"
    TTZ="${3}"

    MSG="Converting ${INPUT_DATE} from ${STZ} to ${TTZ}"

    if [[ $STZ == "EST" ]]; then STZ="EST5EDT"; MSG+=" S+DST"; fi
    if [[ $TTZ == "EST" ]]; then TTZ="EST5EDT"; MSG+=" T+DST"; fi
    if [[ $STZ == "CST" ]]; then STZ="CST6CDT"; MSG+=" S+DST"; fi
    if [[ $TTZ == "CST" ]]; then TTZ="CST6CDT"; MSG+=" T+DST"; fi

    echo "$MSG"

    # Convert date and time to the target time zone
    converted_date=$(TZ="${TTZ}" date -d"TZ=\"${STZ}\" ${INPUT_DATE}")

    if [ $? -ne 0 ]; then
        echo "Error: Conversion failed. Please check your input and try again."
        return 1
    fi

    echo "Converted Time: $converted_date"
}