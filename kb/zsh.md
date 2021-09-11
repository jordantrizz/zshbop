# Common if statements
## Check command
* if (( $+commands[ls] )); then

## If string is null
* if $poop; then

# Conditionals
## Strings
* string = pattern
* string == pattern
* true if string matches pattern. The two forms are exactly equivalent. The ‘=’ form is the traditional shell syntax (and hence the only one generally used with the test and [ builtins); the ‘==’ form provides compatibility with other sorts of computer language.


* string != pattern
* true if string does not match pattern.
* string =~ regexp

## Switches
* -a file - true if file exists.
* -b file - true if file exists and is a block special file.
* -c file - true if file exists and is a character special file.
* -d file - true if file exists and is a directory.
* -e file - true if file exists.
* -f file - true if file exists and is a regular file.
* -g file - true if file exists and has its setgid bit set.
* -h file - true if file exists and is a symbolic link.
* -k file - true if file exists and has its sticky bit set.
* -n string - true if length of string is non-zero.
* -o option - true if option named option is on. option may be a single character, in which case it is a single letter option name. (See Specifying Options.) When no option named option exists, and the POSIX_BUILTINS option hasn’t been set, return 3 with a warning. If that option is set, return 1 with no warning.
* -p file - true if file exists and is a FIFO special file (named pipe).
* -r file - true if file exists and is readable by current process.
* -s file - true if file exists and has size greater than zero.
* -t fd - true if file descriptor number fd is open and associated with a terminal device. (note: fd is not optional)
* -u file - true if file exists and has its setuid bit set.
* -v varname - true if shell variable varname is set.
* -w file - true if file exists and is writable by current process.
* -x file - true if file exists and is executable by current process. If file exists and is a directory, then the current process has permission to search in the directory.
* -z string -true if length of string is zero.
* -L file - true if file exists and is a symbolic link.
* -O file - true if file exists and is owned by the effective user ID of this process.
* -G file - true if file exists and its group matches the effective group ID of this process.
* -S file - true if file exists and is a socket.
* -N file - true if file exists and its access time is not newer than its modification time.
