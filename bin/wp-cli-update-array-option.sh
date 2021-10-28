#!/usr/bin/env bash
# Bash Scripting Boiler Plate
# -- Parse Command Line Arguments https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--option-name)
    option_name="$2"
    shift # past argument
    shift # past value
    ;;
    -k|--option-key)
    option_key="$2"
    shift # past argument
    shift # past value
    ;;
    -v|--value)
    option_value="$2"
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

if [[ -n $1 ]]; then
    wp_cli_options=$1
fi

help () {
        echo "Usage: wp-cli-update-array-option.sh -n <option-name> -k <option-key> -v <value> <wp-cli options>"
        exit
}

if [ -z "$option_name" ]; then help; fi
if [ -z "$option_key" ]; then help; fi
if [ -z "$option_value" ]; then help; fi

if ! [ -x "$(command -v wp)" ]; then
	echo "wp-cli not installed or not in \$PATH"
	exit
fi

echo "option_name: $option_name"
echo "option_key: $option_key"
echo "option_value: $option_value"
echo "wp_cli_options: $wp_cli_options"

echo -e "\n"
wp ${wp_cli_options} option get ${option_name} --format=json | php -r "
\$option = json_decode( fgets(STDIN) );
\$option->${option_key} = \"${option_value}\";
print_r(\$option);"
echo -e "\n"

read -p "Are you sure you want to insert the above? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	wp ${wp_cli_options} option get ${option_name} --format=json | php -r "
	\$option = json_decode( fgets(STDIN) );
	\$option->${option_key} = \"${option_value}\";
	print json_encode(\$option);
	" | wp ${wp_cli_options} option set ${option_name} --format=json
fi
