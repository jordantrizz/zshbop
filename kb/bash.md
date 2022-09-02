# Bash

# Checking Bash Syntax
## shellcheck
* https://github.com/koalaman/shellcheck
## bash -x
* https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_02_03.html
# Expressions

```python
""" TEST """
[ -a FILE ]	True if FILE exists.
[ -b FILE ]	True if FILE exists and is a block-special file.
[ -c FILE ]	True if FILE exists and is a character-special file.
[ -d FILE ]	True if FILE exists and is a directory.
[ -e FILE ]	True if FILE exists.
[ -f FILE ]	True if FILE exists and is a regular file.
[ -g FILE ]	True if FILE exists and its SGID bit is set.
[ -h FILE ]	True if FILE exists and is a symbolic link.
[ -k FILE ]	True if FILE exists and its sticky bit is set.
[ -p FILE ]	True if FILE exists and is a named pipe (FIFO).
[ -r FILE ]	True if FILE exists and is readable.
[ -s FILE ]	True if FILE exists and has a size greater than zero.
[ -t FD ]	True if file descriptor FD is open and refers to a terminal.
[ -u FILE ]	True if FILE exists and its SUID (set user ID) bit is set.
[ -w FILE ]	True if FILE exists and is writable.
[ -x FILE ]	True if FILE exists and is executable.
[ -O FILE ]	True if FILE exists and is owned by the effective user ID.
[ -G FILE ]	True if FILE exists and is owned by the effective group ID.
[ -L FILE ]	True if FILE exists and is a symbolic link.
[ -N FILE ]	True if FILE exists and has been modified since it was last read.
[ -S FILE ]	True if FILE exists and is a socket.
[ FILE1 -nt FILE2 ]	True if FILE1 has been changed more recently than FILE2, or if FILE1 exists and FILE2 does not.
[ FILE1 -ot FILE2 ]	True if FILE1 is older than FILE2, or is FILE2 exists and FILE1 does not.
[ FILE1 -ef FILE2 ]	True if FILE1 and FILE2 refer to the same device and inode numbers.
[ -o OPTIONNAME ]	True if shell option "OPTIONNAME" is enabled.
[ -z STRING ]	True of the length if "STRING" is zero.
[ -n STRING ] or [ STRING ]	True if the length of "STRING" is non-zero.
[ STRING1 == STRING2 ]	True if the strings are equal. "=" may be used instead of "==" for strict POSIX compliance.
[ STRING1 != STRING2 ]	True if the strings are not equal.
[ STRING1 < STRING2 ]	True if "STRING1" sorts before "STRING2" lexicographically in the current locale.
[ STRING1 > STRING2 ]	True if "STRING1" sorts after "STRING2" lexicographically in the current locale.
[ ARG1 OP ARG2 ]	"OP" is one of -eq, -ne, -lt, -le, -gt or -ge. These arithmetic binary operators return true if "ARG1" is equal to, not equal to, less than, less than or equal to, greater than, or greater than or equal to "ARG2", respectively. "ARG1" and "ARG2" are integers.
```

# Integer Comparison
* -eq is equal to if [ "$a" -eq "$b" ]
* -ne is not equal to if [ "$a" -ne "$b" ]
* -gt is greater than if [ "$a" -gt "$b" ]
* -ge is greater than or equal to if [ "$a" -ge "$b" ]
* -lt is less than if [ "$a" -lt "$b" ]
* -le is less than or equal to if [ "$a" -le "$b" ]
* < is less than (within double parentheses) (("$a" < "$b"))
* <= is less than or equal to (within double parentheses) (("$a" <= "$b"))
* > is greater than (within double parentheses) (("$a" > "$b"))
* >= is greater than or equal to (within double parentheses) (("$a" >= "$b"))

# Dealing with Command Arguments
https://readforlearn.com/how-do-i-parse-command-line-arguments-in-bash/
```
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -e|--extension)
    EXTENSION="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--searchpath)
    SEARCHPATH="$2"
    shift # past argument
    shift # past value
    ;;
    -l|--lib)
    LIBPATH="$2"
    shift # past argument
    shift # past value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo "FILE EXTENSION  = ${EXTENSION}"
echo "SEARCH PATH     = ${SEARCHPATH}"
echo "LIBRARY PATH    = ${LIBPATH}"
echo "DEFAULT         = ${DEFAULT}"
echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 "$1"
fi
EOF
```

# Date and Time!
```
enddate=$(date "+%d/%m/%Y %H:%M:%S +%Z");
```

# Pid File Snippet
* https://gist.github.com/darth-veitcher/f47eb0a52ae42a1c5e9a65adca460723

# String Matching in Substring
https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
```
#!/bin/bash

STR='GNU/Linux is an operating system'
SUB='Linux'
if [[ "$STR" == *"$SUB"* ]]; then
  echo "It's there."
fi
```

# Get function name
```${FUNCNAME[0]```

# Run command outside of an alias
* https://unix.stackexchange.com/questions/39291/run-a-command-that-is-shadowed-by-an-alias
* You can also prefix a back slash to disable the alias: \ls
* Edit: Other ways of doing the same include:
* Use "command": command ls as per Mikel.
* Use the full path: /bin/ls as per uther.
* Quote the command: "ls" or 'ls' as per Mikel comment.
* You can remove the alias temporarily for that terminal session with unalias command_name.