#!/usr/bin/env bash
### Created by Peter Forret ( pforret ) on 2021-01-03
script_version="0.0.1" # if there is a VERSION.md in this script's folder, it will take priority for version number
readonly script_author="peter@forret.com"
readonly script_created="2021-01-03"
readonly run_as_root=-1 # run_as_root: 0 = don't check anything / 1 = script MUST run as root / -1 = script MAY NOT run as root

list_options() {
  echo -n "
#commented lines will be filtered
flag|h|help|show usage
flag|q|quiet|no output
flag|v|verbose|output more
flag|f|force|do not ask for confirmation (always yes)
option|l|log_dir|folder for log files |$HOME/log/$script_prefix
option|t|tmp_dir|folder for temp files|.tmp
option|F|from|from: address|$script_author
option|T|to|to: address|example@example.com
option|C|cc|cc: address|
option|B|bcc|bcc: address|
option|G|tag|email tag|test
option|S|subject|email subject|Mail from $USER@$HOSTNAME - $execution_day
option|K|token|Postmark API server token|POSTMARK_API_TEST
option|M|stream|Postmark stream|outbound
option|P|post_url|URL where incoming email should be posted|http://localhost/laravel-mailbox/postmark
param|1|action|action to perform: check/html/text
param|?|input|input text or html
" |
    grep -v '^#' |
    sort
}

list_dependencies() {
  ### Change the next lines to reflect which binaries(programs) or scripts are necessary to run this script
  # Example 1: a regular package that should be installed with apt/brew/yum/...
  #curl
  # Example 2: a program that should be installed with apt/brew/yum/... through a package with a different name
  #convert|imagemagick
  # Example 3: a package with its own package manager: basher (shell), go get (golang), cargo (Rust)...
  #progressbar|basher install pforret/progressbar
  echo -n "
awk
curl
jq
heml|npm install heml -g
pandoc
" |
    grep -v "^#" |
    sort
}

#####################################################################
## Put your main script here
#####################################################################

main() {
  debug "Program: $script_basename $script_version"
  debug "Created: $script_created"
  debug "Updated: $script_modified"
  debug "Run as : $USER@$HOSTNAME"

  require_binaries
  log_to_file "[$script_basename] $script_version started"

  action=$(lower_case "$action")
  case $action in
  check)
    #TIP: use «$script_prefix check» to check if this script is ready to execute (all necessary binaries/scripts exist)
    #TIP:> $script_prefix check
    echo -n "## $char_succ Dependencies: "
    list_dependencies | cut -d'|' -f1 | sort | xargs
    echo "## $char_succ Use this for your .env"
    number_pattern='^[0-9\.]+$'
    list_options \
    | grep -v 'param|' \
    | cut -d'|' -f3 \
    | while read -r option; do
        [[ -n "$option" ]] || continue
        echo -n "$option="
        value="$(eval "echo \$$option")"
        if [[ $value =~ $number_pattern ]] ; then
          echo "$value"
        else
          echo "\"$value\""
        fi
    done
    ;;

  md|markdown)
    #TIP: use «$script_prefix md» send a Markdown formatted email
    #TIP:> $script_prefix md input.md
    # shellcheck disable=SC2154
    if [[ -n "$input" ]] ; then
      md_file="$input"
    else
      md_file="$tmp_dir/$execution_day.$$.body.md"
      cat > "$md_file"
    fi
    debug "Input: [$md_file]"
    text_file="$md_file"
    html_file="$tmp_dir/$execution_day.$$.body.html"
    convert_md_html "$md_file" "$html_file"
    do_send_email "$html_file" "$text_file"
    ;;

  html)
    #TIP: use «$script_prefix html» send a HTML formatted email
    #TIP:> $script_prefix html input.html
    # shellcheck disable=SC2154
    if [[ -n "$input" ]] ; then
      html_file="$input"
    else
      html_file="$tmp_dir/$execution_day.$$.body.html"
      cat > "$html_file"
    fi
    debug "Input: [$html_file]"
    text_file="$tmp_dir/$execution_day.$$.body.txt"
    convert_html_text "$html_file" "$text_file"
    do_send_email "$html_file" "$text_file"
    ;;

  text)
    #TIP: use «$script_prefix text» to send a text formatted email
    #TIP:> $script_prefix text input.txt
    # shellcheck disable=SC2154
    if [[ -n "$input" ]] ; then
      text_file="$input"
    else
      text_file="$tmp_dir/$execution_day.$$.body.txt"
      cat > "$text_file"
    fi
    debug "Input: [$text_file]"
    html_file="$tmp_dir/$execution_day.$$.body.html"
    convert_text_html "$text_file" "$html_file"
    do_send_email "$html_file" "$text_file"
    ;;

  post)
    #TIP: use «$script_prefix post» to post a Postmark inbound-like email to an endpoint
    #TIP:> $script_prefix post input.txt
    # shellcheck disable=SC2154
    if [[ -n "$input" ]] ; then
      text_file="$input"
    else
      text_file="$tmp_dir/$execution_day.$$.body.txt"
      cat > "$text_file"
    fi
    debug "Input: [$text_file]"
    html_file="$tmp_dir/$execution_day.$$.body.html"
    convert_text_html "$text_file" "$html_file"
    # shellcheck disable=SC2154
    do_post_email "$html_file" "$text_file" "$post_url"

    ;;
  *)
    die "action [$action] not recognized"
    ;;
  esac
  log_to_file "[$script_basename] ended after $SECONDS secs"
  #TIP: >>> bash script created with «pforret/bashew»
  #TIP: >>> for developers, also check «pforret/setver»
}

#####################################################################
## Put your helper scripts here
#####################################################################

do_send_email() {
  # $1 = html body file
  # $2 = text body file

  # shellcheck disable=SC2154
  debug "Send mail: [$from] -> [$to] ($subject)"
  # shellcheck disable=SC2154
  debug "API: stream $stream, Token $token"

  json_request="$tmp_dir/$execution_day.$$.request.json"
  json_response="$tmp_dir/$execution_day.$$.response.json"

  jq \
    --arg From "$from" \
    --arg To "$to" \
    --arg Subject "$subject" \
    --arg TextBody "$(< "$2")" \
    --arg HtmlBody "$(< "$1")" \
    --arg MessageStream "$stream" \
    '.
    | .From=$From
    | .To=$To
    | .Subject=$Subject
    | .TextBody=$TextBody
    | .HtmlBody=$HtmlBody
    | .MessageStream=$MessageStream
    ' \
    <<<'{}' > "$json_request"
    debug "JSON request: $json_request"

  curl -s "https://api.postmarkapp.com/email" \
    -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Postmark-Server-Token: $token" \
    -d @"$json_request" \
    > "$json_response"
    ((quiet)) || < "$json_response" jq "."

}

do_post_email(){
  # $1 = html body file
  # $2 = text body file
  # $3 = post URL

  # shellcheck disable=SC2154
  debug "Post mail: [$from] -> [$to] ($subject)"
  # shellcheck disable=SC2154
  debug "API: stream $stream, Token $token"

  json_request="$tmp_dir/$execution_day.$$.request.json"
  json_response="$tmp_dir/$execution_day.$$.response.json"

}

convert_text_html() {
  # $1 = input file
  # $2 = output file
  temp_heml="$tmp_dir/$execution_day.$$.convert.heml"
  temp_html="$tmp_dir/$execution_day.$$.convert.html"
  # shellcheck disable=SC2154
  awk \
  -v subject="$subject" \
  -v preview="$(< "$1" tr "\n" " " | cut -d' ' -f1-50)" \
  -v body="$(cat "$1")" \
  '
  {
  gsub(/{{subject}}/, subject);
  gsub(/{{body}}/, body);
  gsub(/{{preview}}/, preview);
  print;
  }
  ' \
  < "$script_install_folder/template/email.heml" \
  > "$temp_heml"

  heml build "$temp_heml" && cp "$temp_html" "$2"
  debug "convert_text_html -> $2"
 }

convert_md_html() {
  # $1 = input file
  # $2 = output file
  pandoc --metadata title="$subject" -s "$1" -o "$2"
  debug "convert_md_html -> $2"
}

convert_html_text() {
  # $1 = input file
  # $2 = output file
  pandoc -s "$1" -o "$2"
  debug "convert_html_text -> $2"
}

#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################
#####################################################################

# set strict mode -  via http://redsymbol.net/articles/unofficial-bash-strict-mode/
# removed -e because it made basic [[ testing ]] difficult
set -uo pipefail
IFS=$'\n\t'
# shellcheck disable=SC2120
hash() {
  length=${1:-6}
  # shellcheck disable=SC2230
  if [[ -n $(which md5sum) ]]; then
    # regular linux
    md5sum | cut -c1-"$length"
  else
    # macos
    md5 | cut -c1-"$length"
  fi
}

force=0
help=0
verbose=0
#to enable verbose even before option parsing
[[ $# -gt 0 ]] && [[ $1 == "-v" ]] && verbose=1
quiet=0
#to enable quiet even before option parsing
[[ $# -gt 0 ]] && [[ $1 == "-q" ]] && quiet=1

initialise_output() {
  [[ "${BASH_SOURCE[0]:-}" != "${0}" ]] && sourced=1 || sourced=0
  [[ -t 1 ]] && piped=0 || piped=1 # detect if output is piped
  if [[ $piped -eq 0 ]]; then
    col_reset="\033[0m"
    col_red="\033[1;31m"
    col_grn="\033[1;32m"
    col_ylw="\033[1;33m"
  else
    col_reset=""
    col_red=""
    col_grn=""
    col_ylw=""
  fi

  [[ $(echo -e '\xe2\x82\xac') == '€' ]] && unicode=1 || unicode=0 # detect if unicode is supported
  if [[ $unicode -gt 0 ]]; then
    char_succ="✔"
    char_fail="✖"
    char_alrt="➨"
    char_wait="…"
  else
    char_succ="OK "
    char_fail="!! "
    char_alrt="?? "
    char_wait="..."
  fi
  error_prefix="${col_red}>${col_reset}"

  readonly nbcols=$(tput cols 2>/dev/null || echo 80)
  readonly wprogress=$((nbcols - 5))
}

out() { ((quiet)) || printf '%b\n' "$*"; }
debug() { ((verbose)) && out "${col_ylw}# $* ${col_reset}" >&2; }
die() {
  out "${col_red}${char_fail} $script_basename${col_reset}: $*" >&2
  tput bel
  safe_exit
}
alert() { out "${col_red}${char_alrt}${col_reset}: $*" >&2; } # print error and continue
success() { out "${col_grn}${char_succ}${col_reset}  $*"; }
announce() {
  out "${col_grn}${char_wait}${col_reset}  $*"
  sleep 1
}

progress() {
  ((quiet)) || (
    if is_set ${piped:-0}; then
      out "$*" >&2
    else
      printf "... %-${wprogress}b\r" "$*                                             " >&2
    fi
  )
}

log_to_file() { [[ -n ${log_file:-} ]] && echo "$(date '+%H:%M:%S') | $*" >>"$log_file"; }

lower_case() { echo "$*" | awk '{print tolower($0)}'; }
upper_case() { echo "$*" | awk '{print toupper($0)}'; }

slugify() {
  # shellcheck disable=SC2020

  lower_case "$*" |
    tr \
      'àáâäæãåāçćčèéêëēėęîïííīįìłñńôöòóœøōõßśšûüùúūÿžźż' \
      'aaaaaaaaccceeeeeeeiiiiiiilnnoooooooosssuuuuuyzzz' |
    awk '{
    gsub(/[^0-9a-z ]/,"");
    gsub(/^\s+/,"");
    gsub(/^s+$/,"");
    gsub(" ","-");
    print;
    }' |
    cut -c1-50
}

confirm() {
  # $1 = question
  is_set $force && return 0
  read -r -p "$1 [y/N] " -n 1
  echo " "
  [[ $REPLY =~ ^[Yy]$ ]]
}

ask() {
  # $1 = variable name
  # $2 = question
  # $3 = default value
  # not using read -i because that doesn't work on MacOS
  local ANSWER
  read -r -p "$2 ($3) > " ANSWER
  if [[ -z "$ANSWER" ]]; then
    eval "$1=\"$3\""
  else
    eval "$1=\"$ANSWER\""
  fi
}

trap "die \"ERROR \$? after \$SECONDS seconds \n\
\${error_prefix} last command : '\$BASH_COMMAND' \" \
\$(< \$script_install_path awk -v lineno=\$LINENO \
'NR == lineno {print \"\${error_prefix} from line \" lineno \" : \" \$0}')" INT TERM EXIT
# cf https://askubuntu.com/questions/513932/what-is-the-bash-command-variable-good-for

safe_exit() {
  [[ -n "${tmp_file:-}" ]] && [[ -f "$tmp_file" ]] && rm "$tmp_file"
  trap - INT TERM EXIT
  debug "$script_basename finished after $SECONDS seconds"
  exit 0
}

is_set() { [[ "$1" -gt 0 ]]; }
is_empty() { [[ -z "$1" ]]; }
is_not_empty() { [[ -n "$1" ]]; }

is_file() { [[ -f "$1" ]]; }
is_dir() { [[ -d "$1" ]]; }

show_usage() {
  out "Program: ${col_grn}$script_basename $script_version${col_reset} by ${col_ylw}$script_author${col_reset}"
  out "Updated: ${col_grn}$script_modified${col_reset}"
  out "Description: Use Postmark API on the command line"
  echo -n "Usage: $script_basename"
  list_options |
    awk '
  BEGIN { FS="|"; OFS=" "; oneline="" ; fulltext="Flags, options and parameters:"}
  $1 ~ /flag/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [flag] %s [default: off]",$2,$3,$4) ;
    oneline  = oneline " [-" $2 "]"
    }
  $1 ~ /option/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [option] %s",$2,$3 " <?>",$4) ;
    if($5!=""){fulltext = fulltext "  [default: " $5 "]"; }
    oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /secret/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [secr] %s",$2,$3,"?",$4) ;
      oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /param/ {
    if($2 == "1"){
          fulltext = fulltext sprintf("\n    %-17s: [parameter] %s","<"$3">",$4);
          oneline  = oneline " <" $3 ">"
     }
     if($2 == "?"){
          fulltext = fulltext sprintf("\n    %-17s: [parameter] %s (optional)","<"$3">",$4);
          oneline  = oneline " <" $3 "?>"
     }
     if($2 == "n"){
          fulltext = fulltext sprintf("\n    %-17s: [parameters] %s (1 or more)","<"$3">",$4);
          oneline  = oneline " <" $3 " …>"
     }
    }
    END {print oneline; print fulltext}
  '
}

show_tips() {
  ((sourced)) && return 0
  grep <"${BASH_SOURCE[0]}" -v "\$0" |
    awk "
  /TIP: / {\$1=\"\"; gsub(/«/,\"$col_grn\"); gsub(/»/,\"$col_reset\"); print \"*\" \$0}
  /TIP:> / {\$1=\"\"; print \" $col_ylw\" \$0 \"$col_reset\"}
  " |
    awk \
      -v script_basename="$script_basename" \
      -v script_prefix="$script_prefix" \
      '{
    gsub(/\$script_basename/,script_basename);
    gsub(/\$script_prefix/,script_prefix);
    print ;
    }'
}

init_options() {
  local init_command
  init_command=$(list_options |
    awk '
    BEGIN { FS="|"; OFS=" ";}
    $1 ~ /flag/   && $5 == "" {print $3 "=0; "}
    $1 ~ /flag/   && $5 != "" {print $3 "=\"" $5 "\"; "}
    $1 ~ /option/ && $5 == "" {print $3 "=\"\"; "}
    $1 ~ /option/ && $5 != "" {print $3 "=\"" $5 "\"; "}
    ')
  if [[ -n "$init_command" ]]; then
    eval "$init_command"
  fi
}

require_binaries() {
  os_name=$(uname -s)
  os_version=$(uname -prm)
  debug "Running: $os_name ($os_version)"
  [[ -n "${ZSH_VERSION:-}" ]] && debug "Running: zsh $ZSH_VERSION"
  [[ -n "${BASH_VERSION:-}" ]] && debug "Running: bash $BASH_VERSION"
  local required_binary
  local install_instructions

  while read -r line; do
    required_binary=$(echo "$line" | cut -d'|' -f1)
    [[ -z "$required_binary" ]] && continue
    # shellcheck disable=SC2230
    debug "Check for existence of [$required_binary]"
    [[ -n $(which "$required_binary") ]] && continue
    required_package=$(echo "$line" | cut -d'|' -f2)
    if [[ $(echo "$required_package" | wc -w) -gt 1 ]]; then
      # example: setver|basher install setver
      install_instructions="$required_package"
    else
      [[ -z "$required_package" ]] && required_package="$required_binary"
      if [[ -n "$install_package" ]]; then
        install_instructions="$install_package $required_package"
      else
        install_instructions="(install $required_package with your package manager)"
      fi
    fi
    alert "$script_basename needs [$required_binary] but it cannot be found"
    alert "1) install package  : $install_instructions"
    alert "2) check path       : export PATH=\"[path of your binary]:\$PATH\""
    die "Missing program/script [$required_binary]"
  done < <(list_dependencies)
}

folder_prep() {
  if [[ -n "$1" ]]; then
    local folder="$1"
    local max_days=${2:-365}
    if [[ ! -d "$folder" ]]; then
      debug "Create folder : [$folder]"
      mkdir -p "$folder"
    else
      debug "Cleanup folder: [$folder] - delete files older than $max_days day(s)"
      find "$folder" -mtime "+$max_days" -type f -exec rm {} \;
    fi
  fi
}

expects_single_params() {
  list_options | grep 'param|1|' >/dev/null
}
expects_optional_params() {
  list_options | grep 'param|?|' >/dev/null
}
expects_multi_param() {
  list_options | grep 'param|n|' >/dev/null
}

count_words() {
  wc -w |
    awk '{ gsub(/ /,""); print}'
}

parse_options() {
  if [[ $# -eq 0 ]]; then
    show_usage >&2
    safe_exit
  fi

  ## first process all the -x --xxxx flags and options
  while true; do
    # flag <flag> is saved as $flag = 0/1
    # option <option> is saved as $option
    if [[ $# -eq 0 ]]; then
      ## all parameters processed
      break
    fi
    if [[ ! $1 == -?* ]]; then
      ## all flags/options processed
      break
    fi
    local save_option
    save_option=$(list_options |
      awk -v opt="$1" '
        BEGIN { FS="|"; OFS=" ";}
        $1 ~ /flag/   &&  "-"$2 == opt {print $3"=1"}
        $1 ~ /flag/   && "--"$3 == opt {print $3"=1"}
        $1 ~ /option/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /option/ && "--"$3 == opt {print $3"=$2; shift"}
        $1 ~ /secret/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /secret/ && "--"$3 == opt {print $3"=$2; shift"}
        ')
    if [[ -n "$save_option" ]]; then
      if echo "$save_option" | grep shift >>/dev/null; then
        local save_var
        save_var=$(echo "$save_option" | cut -d= -f1)
        debug "Found  : ${save_var}=$2"
      else
        debug "Found  : $save_option"
      fi
      eval "$save_option"
    else
      die "cannot interpret option [$1]"
    fi
    shift
  done

  ((help)) && (
    echo "### USAGE"
    show_usage
    echo ""
    echo "### TIPS & EXAMPLES"
    show_tips
    safe_exit
  )

  ## then run through the given parameters
  if expects_single_params; then
    single_params=$(list_options | grep 'param|1|' | cut -d'|' -f3)
    list_singles=$(echo "$single_params" | xargs)
    single_count=$(echo "$single_params" | count_words)
    debug "Expect : $single_count single parameter(s): $list_singles"
    [[ $# -eq 0 ]] && die "need the parameter(s) [$list_singles]"

    for param in $single_params; do
      [[ $# -eq 0 ]] && die "need parameter [$param]"
      [[ -z "$1" ]] && die "need parameter [$param]"
      debug "Assign : $param=$1"
      eval "$param=\"$1\""
      shift
    done
  else
    debug "No single params to process"
    single_params=""
    single_count=0
  fi

  if expects_optional_params; then
    optional_params=$(list_options | grep 'param|?|' | cut -d'|' -f3)
    optional_count=$(echo "$optional_params" | count_words)
    debug "Expect : $optional_count optional parameter(s): $(echo "$optional_params" | xargs)"

    for param in $optional_params; do
      debug "Assign : $param=${1:-}"
      eval "$param=\"${1:-}\""
      shift
    done
  else
    debug "No optional params to process"
    optional_params=""
    optional_count=0
  fi

  if expects_multi_param; then
    #debug "Process: multi param"
    multi_count=$(list_options | grep -c 'param|n|')
    multi_param=$(list_options | grep 'param|n|' | cut -d'|' -f3)
    debug "Expect : $multi_count multi parameter: $multi_param"
    ((multi_count > 1)) && die "cannot have >1 'multi' parameter: [$multi_param]"
    ((multi_count > 0)) && [[ $# -eq 0 ]] && die "need the (multi) parameter [$multi_param]"
    # save the rest of the params in the multi param
    if [[ -n "$*" ]]; then
      debug "Assign : $multi_param=$*"
      eval "$multi_param=( $* )"
    fi
  else
    multi_count=0
    multi_param=""
    [[ $# -gt 0 ]] && die "cannot interpret extra parameters"
  fi
}

recursive_readlink() {
  [[ ! -L "$1" ]] && echo "$1" && return 0
  local file_folder
  local link_folder
  local link_name
  file_folder="$(dirname "$1")"
  # resolve relative to absolute path
  [[ "$file_folder" != /* ]] && link_folder="$(cd -P "$file_folder" &>/dev/null && pwd)"
  local symlink
  symlink=$(readlink "$1")
  link_folder=$(dirname "$symlink")
  link_name=$(basename "$symlink")
  [[ -z "$link_folder" ]] && link_folder="$file_folder"
  [[ "$link_folder" == \.* ]] && link_folder="$(cd -P "$file_folder" && cd -P "$link_folder" &>/dev/null && pwd)"
  debug "Symbolic ln: $1 -> [$symlink]"
  recursive_readlink "$link_folder/$link_name"
}

lookup_script_data() {
  readonly script_prefix=$(basename "${BASH_SOURCE[0]}" .sh)
  readonly script_basename=$(basename "${BASH_SOURCE[0]}")
  readonly execution_day=$(date "+%Y-%m-%d")
  #readonly execution_year=$(date "+%Y")

  script_install_path="${BASH_SOURCE[0]}"
  debug "Script path: $script_install_path"
  script_install_path=$(recursive_readlink "$script_install_path")
  debug "Actual path: $script_install_path"
  readonly script_install_folder="$(dirname "$script_install_path")"
  if [[ -f "$script_install_path" ]]; then
    script_hash=$(hash <"$script_install_path" 8)
    script_lines=$(awk <"$script_install_path" 'END {print NR}')
  else
    # can happen when script is sourced by e.g. bash_unit
    script_hash="?"
    script_lines="?"
  fi

  # get shell/operating system/versions
  shell_brand="sh"
  shell_version="?"
  [[ -n "${ZSH_VERSION:-}" ]] && shell_brand="zsh" && shell_version="$ZSH_VERSION"
  [[ -n "${BASH_VERSION:-}" ]] && shell_brand="bash" && shell_version="$BASH_VERSION"
  [[ -n "${FISH_VERSION:-}" ]] && shell_brand="fish" && shell_version="$FISH_VERSION"
  [[ -n "${KSH_VERSION:-}" ]] && shell_brand="ksh" && shell_version="$KSH_VERSION"
  debug "Shell type : $shell_brand - version $shell_version"

  readonly os_kernel=$(uname -s)
  os_version=$(uname -r)
  os_machine=$(uname -m)
  install_package=""
  case "$os_kernel" in
  CYGWIN* | MSYS* | MINGW*)
    os_name="Windows"
    ;;
  Darwin)
    os_name=$(sw_vers -productName)       # macOS
    os_version=$(sw_vers -productVersion) # 11.1
    install_package="brew install"
    ;;
  Linux | GNU*)
    if [[ $(which lsb_release) ]]; then
      # 'normal' Linux distributions
      os_name=$(lsb_release -i)    # Ubuntu
      os_version=$(lsb_release -r) # 20.04
    else
      # Synology, QNAP,
      os_name="Linux"
    fi
    [[ -x /bin/apt-cyg ]] && install_package="apt-cyg install"     # Cygwin
    [[ -x /bin/dpkg ]] && install_package="dpkg -i"                # Synology
    [[ -x /opt/bin/ipkg ]] && install_package="ipkg install"       # Synology
    [[ -x /usr/sbin/pkg ]] && install_package="pkg install"        # BSD
    [[ -x /usr/bin/pacman ]] && install_package="pacman -S"        # Arch Linux
    [[ -x /usr/bin/zypper ]] && install_package="zypper install"   # Suse Linux
    [[ -x /usr/bin/emerge ]] && install_package="emerge"           # Gentoo
    [[ -x /usr/bin/yum ]] && install_package="yum install"         # RedHat RHEL/CentOS/Fedora
    [[ -x /usr/bin/apk ]] && install_package="apk add"             # Alpine
    [[ -x /usr/bin/apt-get ]] && install_package="apt-get install" # Debian
    [[ -x /usr/bin/apt ]] && install_package="apt install"         # Ubuntu
    ;;

  esac
  debug "System OS  : $os_name ($os_kernel) $os_version on $os_machine"
  debug "Package mgt: $install_package"

  # get last modified date of this script
  script_modified="??"
  [[ "$os_kernel" == "Linux" ]] && script_modified=$(stat -c %y "$script_install_path" 2>/dev/null | cut -c1-16) # generic linux
  [[ "$os_kernel" == "Darwin" ]] && script_modified=$(stat -f "%Sm" "$script_install_path" 2>/dev/null)          # for MacOS

  debug "Last modif : $script_modified"
  debug "Script ID  : $script_lines lines / md5: $script_hash"

  # get script version from VERSION.md file - which is automatically updated by pforret/setver
  [[ -f "$script_install_folder/VERSION.md" ]] && script_version=$(cat "$script_install_folder/VERSION.md")

  # if run inside a git repo, detect for which remote repo it is
  if git status &>/dev/null; then
    readonly git_repo_remote=$(git remote -v | awk '/(fetch)/ {print $2}')
    debug "git remote : $git_repo_remote"
    readonly git_repo_root=$(git rev-parse --show-toplevel)
    debug "git folder : $git_repo_root"
  else
    readonly git_repo_root=""
    readonly git_repo_remote=""
  fi
}

prep_log_and_temp_dir() {
  tmp_file=""
  log_file=""
  if [[ -n "${tmp_dir:-}" ]]; then
    folder_prep "$tmp_dir" 1
    tmp_file=$(mktemp "$tmp_dir/$execution_day.XXXXXX")
    debug "tmp_file: $tmp_file"
    # you can use this temporary file in your program
    # it will be deleted automatically if the program ends without problems
  fi
  if [[ -n "${log_dir:-}" ]]; then
    folder_prep "$log_dir" 7
    log_file=$log_dir/$script_prefix.$execution_day.log
    debug "log_file: $log_file"
  fi
}

import_env_if_any() {
  env_files=("$script_install_folder/.env" "$script_install_folder/$script_prefix.env" "./.env" "./$script_prefix.env")

  for env_file in "${env_files[@]}"; do
    if [[ -f "$env_file" ]]; then
      debug "Read config from [$env_file]"
      # shellcheck disable=SC1090
      source "$env_file"
    fi
  done
}

[[ $run_as_root == 1 ]] && [[ $UID -ne 0 ]] && die "user is $USER, MUST be root to run [$script_basename]"
[[ $run_as_root == -1 ]] && [[ $UID -eq 0 ]] && die "user is $USER, CANNOT be root to run [$script_basename]"

initialise_output  # output settings
lookup_script_data # find installation folder
init_options       # set default values for flags & options
import_env_if_any  # overwrite with .env if any

if [[ $sourced -eq 0 ]]; then
  parse_options "$@"    # overwrite with specified options if any
  prep_log_and_temp_dir # clean up debug and temp folder
  main                  # run main program
  safe_exit             # exit and clean up
else
  # just disable the trap, don't execute main
  trap - INT TERM EXIT
fi
