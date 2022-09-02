#!/bin/env bash

# -- variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
START_USERS=10
STOP_USERS=10010

if [[ -f ${SCRIPT_DIR}/.debug ]]; then
    DEBUG=1
fi

##############
# -- functions
##############

_debug () {
    if [[ $DEBUG == 1 ]]; then
        echo "** DEBUG: $@";
    fi
}

usage () {
	echo "This script creates wordpress users for a the loadstorm.js test script."
	echo ""
	echo "Usage: setup.sh -s [-su|-st|-d]"
	echo "                -h"
	echo "                -r [users|import]"
	echo ""
	echo "Commands:"
	echo "   -s                   - Start the script"
	echo "   -h                   - This help"
	echo "   -r [users|import]    - Run specific script"
	echo ""
	echo "Options:"
	echo "   -su    - Start user number"
	echo "   -st	- Stop user number"
	echo "   -d     - Turn on debug"	
}

setup_users () {
	echo "  -- Creating WordPress test users"	
	for TEST_USERNAME_I in {$START_USERS..$STOP_USERS}; do
		TEST_PASSWORD="password$RANDOM"
		_debug "wp --allow-root user create username${TEST_USERNAME_I} username${TEST_USERNAME_I}@example.com --role=\"subscriber\" --user_pass=\"$TEST_PASSWORD\""
        wp --allow-root user create username${TEST_USERNAME_I} username${TEST_USERNAME_I}@example.com --role="subscriber" --user_pass="$TEST_PASSWORD"
	done;
}


##############
# -- main loop
##############

# -- positional args
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"
 
  case $key in
    -s|--start)
      COMMAND="start"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      COMMAND="help"
      shift # past argument
      shift # past value
      ;;
    -r|--run)
      COMMAND="run"
      COMMAND_RUN="$2"
      shift # past argument
      shift # past value
      ;;
    -su)
      START_USERS="$2"
      shift # past argument
      shift # past value
      ;;
    -st)
      STOP_USERS="$2"
      shift # past argument
      shift # past value
      ;;
    -d)
      DEBUG="1"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
 
set -- "${POSITIONAL[@]}" # restore positional parameters

# -- debug

if [[ $DEBUG == "1" ]]; then
    echo "## Debug Enabled ##"
    echo "## \$DEBUG = $DEBUG"
    echo "## \$COMMAND = $COMMAND"
    echo "## \$COMMAND = $COMMAND_RUN"
    echo "## \$START_USERS = $START_USERS"
    echo "## \$STOP_USERS = $STOP_USERS"
else
    echo "- Debug disabled."
fi

# -- start
 
if [[ $COMMAND == "help" ]]; then
	usage
	exit
elif [[ $COMMAND == "start" ]]; then
	echo "- Starting setup."
	echo "- Running from $SCRIPT_DIR"
	setup_users	
elif [[ $COMMAND == "run" ]] && [[ -n $COMMAND_RUN ]]; then
	echo "Running $COMMAND_RUN"	
else
	usage
	exit
fi