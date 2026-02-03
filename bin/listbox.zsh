#!env /bin/zsh

# -- Variables
zparseopts -D -E h=help -help=help t+:=title o+:=opts r=result -result=result a=arrow -arrow=arrow

title=$title[2]
opts=$opts[2]
result=$result[2]
arrow=$arrow[2]

IFS=$'\n' opts=($(echo "$opts" | tr "|" "\n"))

# -- Functions
usage () {
        echo "Usage: listbox [options]"
        echo "Example:"
        echo "  listbox -t \"title\" -o \"option 1|option 2|option 3\" -r resultVariable -a '>'"
        echo "Options:"
        echo "  -h, --help                         help"
        echo "  -t, --title                        list title"
        echo "  -o, --options \"option 1|option 2\"  listbox options"
        echo "  -r, --result <var>                 result variable"
        echo "  -a, --arrow <symbol>               selected option symbol"
        echo ""
}


if [[ $help ]]; then
	usage
	exit
fi

if [[ -z $title ]] || [[ -z $opts ]]; then
	echo "Error: need at least -t or -z specified"
	echo ""
	usage
	exit 
fi

listbox () {
  if [[ -z $arrow ]]; then
    arrow=">"
  fi

  local len=${#opts[@]}

  local choice=0
  local titleLen=${#title}

  if [[ -n "$title" ]]; then
    echo -e "\n  $title"
    printf "  "
    printf %"$titleLen"s | tr " " "-"
    echo ""
  fi

  draw() {
    local idx=0 
    for it in "${opts[@]}"
    do
      local str="";
      if [ $idx -eq $choice ]; then
        str+="$arrow "
      else
        str+="  "
      fi
      echo "$str$it"
      idx=$((idx+1))
    done
  }

  move() {
    for it in "${opts[@]}"
    do
      tput cuu1
    done
    tput el1
  }

  listen() {
    while true
    do
      key=$(bash -c "read -n 1 -s key; echo \$key")

      if [[ $key = q ]]; then
        break
      elif [[ $key = B ]]; then
        if [ $choice -lt $((len-1)) ]; then
          choice=$((choice+1))
          move
          draw
        fi
      elif [[ $key = A ]]; then
        if [ $choice -gt 0 ]; then
          choice=$((choice-1))
          move
          draw
        fi
      elif [[ $key = "" ]]; then
        # check if zsh/bash
          choice=$((choice+1))

        if [[ -n $__result ]]; then
          eval "$__result=\"${opts[$choice]}\""
        else
          echo -e "\n${opts[$choice]}"
        fi
        break
      fi
    done
  }

  draw
  listen
}

#echo "-- Working"
listbox $@
