# Install ZSH
## romkatv Staticly Linked ZSH
* https://github.com/romkatv/zsh-bin
* ```sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)"```
## Compile ZSH on CentOS 6 
### ZSH 5.1.1
```
wget https://www.zsh.org/pub/old/zsh-5.1.1.tar.xz
tar --strip-components=1 -xvf zsh-5.1.1-doc.tar.xz
./Util/preconfig
./configure
make
make install
```
### ZSH 5.4.2
```
wget https://www.zsh.org/pub/old/zsh-5.4.2.tar.gz --no-check-certificate
./Util/preconfig
./configure
make
make install
```

## Make CentOS 7 ZSH 5.7
```
sudo yum update -y
sudo yum install -y git make ncurses-devel gcc autoconf man yodl
git clone -b zsh-5.7.1 https://github.com/zsh-users/zsh.git /tmp/zsh
cd /tmp/zsh
./Util/preconfig
./configure
sudo make -j 20 install
```

## Ubuntu 14
```
apt-get install libncurses5-dev
git clone -b zsh-5.7.1 https://github.com/zsh-users/zsh.git /tmp/zsh
cd /tmp/zsh
./Util/preconfig
./configure
sudo make -j 20 install
```

# Common ZSH Errors
## zsh compinit: insecure directories
Some core functions of ZSH are not accessiable due to insecure directories, this might be related to permissions or ownership (user/group)
* https://stackoverflow.com/questions/13762280/zsh-compinit-insecure-directories
```
chmod -R 755 /usr/local/share/zsh/site-functions
chown -R root:root /usr/local/share/zsh/site-functions
```

## failed to load module: zsh/regex
Most likely missing zsh modules, re-install or re-compile zsh

# Debug ZSH
## ZSH Trace
```zsh -xv```
## ZSH Trace + Log
```zsh -xv 2> debug.err.txt```

# ZSH Expansion + Pattern Matching
* https://thevaluable.dev/zsh-expansion-guide-example/

# Arguments
* $1 first argument
* $@ all arguments

# Common if statements
## Check command
* if (( $+commands[ls] )); then

## If string is null
* if $poop; then

# Conditionals
## Strings
* string = pattern = true if string matches pattern. The two forms are exactly equivalent. 
* The ‘=’ form is the traditional shell syntax (and hence the only one generally used with the test and [ builtins); the ‘==’ form provides compatibility with other sorts of computer language.

* string == pattern
* string != pattern = true if string does not match pattern.
* string =~ regexp

true if string matches the regular expression regexp. If the option RE_MATCH_PCRE is set regexp is tested as a PCRE regular expression using the zsh/pcre module, else it is tested as a POSIX extended regular expression using the zsh/regex module. Upon successful match, some variables will be updated; no variables are changed if the matching fails.

If the option BASH_REMATCH is not set the scalar parameter MATCH is set to the substring that matched the pattern and the integer parameters MBEGIN and MEND to the index of the start and end, respectively, of the match in string, such that if string is contained in variable var the expression ‘${var[$MBEGIN,$MEND]}’ is identical to ‘$MATCH’. The setting of the option KSH_ARRAYS is respected. Likewise, the array match is set to the substrings that matched parenthesised subexpressions and the arrays mbegin and mend to the indices of the start and end positions, respectively, of the substrings within string. The arrays are not set if there were no parenthesised subexpressions. For example, if the string ‘a short string’ is matched against the regular expression ‘s(...)t’, then (assuming the option KSH_ARRAYS is not set) MATCH, MBEGIN and MEND are ‘short’, 3 and 7, respectively, while match, mbegin and mend are single entry arrays containing the strings ‘hor’, ‘4’ and ‘6’, respectively.

If the option BASH_REMATCH is set the array BASH_REMATCH is set to the substring that matched the pattern followed by the substrings that matched parenthesised subexpressions within the pattern.

* string -eq string
* string1 < string2
* string1 > string2
* exp1 -eq exp2 = true if exp1 is numerically equal to exp2. Note that for purely numeric comparisons use of the ((...)) builtin described in Arithmetic Evaluation is more convenient than conditional expressions.
* exp1 -ne exp2 = true if exp1 is numerically not equal to exp2.
* exp1 -lt exp2 = true if exp1 is numerically less than exp2.
* exp1 -gt exp2 =true if exp1 is numerically greater than exp2.
* exp1 -le exp2 = true if exp1 is numerically less than or equal to exp2.
* exp1 -ge exp2 = true if exp1 is numerically greater than or equal to exp2.
* ( exp ) = true if exp is true.
* ! exp = true if exp is false.
* exp1 && exp2 = true if exp1 and exp2 are both true.
* exp1 || exp2 = true if either exp1 or exp2 is true.

## Switches
* -a file = true if file exists.
* -b file = true if file exists and is a block special file.
* -c file = true if file exists and is a character special file.
* -d file = true if file exists and is a directory.
* -e file = true if file exists.
* -f file = true if file exists and is a regular file.
* -g file = true if file exists and has its setgid bit set.
* -h file = true if file exists and is a symbolic link.
* -k file = true if file exists and has its sticky bit set.
* -n string = true if length of string is non-zero.
* -o option = true if option named option is on. option may be a single character, in which case it is a single letter option name. (See Specifying Options.) When no option named option exists, and the POSIX_BUILTINS option hasn’t been set, return 3 with a warning. If that option is set, return 1 with no warning.
* -p file = true if file exists and is a FIFO special file (named pipe).
* -r file = true if file exists and is readable by current process.
* -s file = true if file exists and has size greater than zero.
* -t fd = true if file descriptor number fd is open and associated with a terminal device. (note: fd is not optional)
* -u file = true if file exists and has its setuid bit set.
* -v varname = true if shell variable varname is set.
* -w file = true if file exists and is writable by current process.
* -x file = true if file exists and is executable by current process. If file exists and is a directory, then the current process has permission to search in the directory.
* -z string -true if length of string is zero.
* -L file = true if file exists and is a symbolic link.
* -O file = true if file exists and is owned by the effective user ID of this process.
* -G file = true if file exists and its group matches the effective group ID of this process.
* -S file = true if file exists and is a socket.
* -N file = true if file exists and its access time is not newer than its modification time.
* file1 -nt file2 = true if file1 exists and is newer than file2.
* file1 -ot file2 = true if file1 exists and is older than file2.
* file1 -ef file2 = true if file1 and file2 exist and refer to the same file.

# True / False and IF Statements
* https://rowannicholls.github.io/bash/intro/booleans.html

## Example 1
```
❯ if false; then echo "true $?"; else echo "false $?"; fi
false 1
❯ if true; then echo "true $?"; else echo "false $?"; fi
true 0
```

## Example 2
```
failed=false 
jobdone=true

if [ foo ]; then ... # "if the string 'foo' is non-empty, return true"
if foo; then ...     # "if the command foo succeeds, return true"

if [ true  ] ; then echo "This text will always appear." ; fi;
if [ false ] ; then echo "This text will always appear." ; fi;
if true      ; then echo "This text will always appear." ; fi;
if false     ; then echo "This text will never appear."  ; fi;

f [ "$foo" = "$bar" ]   # true if the string values of $foo and $bar are equal
if [ "$foo" -eq "$bar" ] # true if the integer values of $foo and $bar are equal
if [ -f "$foo" ]         # true if $foo is a file that exists (by path)
if [ "$foo" ]            # true if $foo evaluates to a non-empty string
if foo                   # true if foo, as a command/subroutine,
                         # evaluates to true/success (returns 0 or null)
```

# Execute Function in a Variable
```
ARGS="-auwxxf"
TEST="ps $args"
$TEST
```

# How to show function definition
```
zsh$ whence -f foo
foo () {
    echo hello
}
zsh$
```
# for/do loop
```
for <item> in <list of items>
do
    <command to run>
done
```
# while/do loop
```
#!/bin/bash

# This generates a file every 5 minutes

while true; do
touch pic-`date +%s`.jpg
sleep 300
done
```

# Dealing with Arrays
## Add to array
```
ARRAY=()
ARRAY+=('foo')
ARRAY+=('bar')
```

### Iterate through Array
```
array=(a b c d)

for element in "${array[@]}"; do
  echo $element
done
```

## String to Array
```
${(@f)SOME_VARIABLE}
DIR_STATUS_ARRAY=("${(f)DIR_STATUS_CMD}")
```

## Associatve Arrays
* See https://scriptingosx.com/2019/11/associative-arrays-in-zsh/
### Example 1
```
userinfo=( name armin shell zsh website scriptingosx.com )
userinfo=( [name]=armin [shell]=zsh [website]="scriptingosx.com" )
% userinfo=( [name]=beth [shell]=zsh )
% if [[ -z $userinfo[website] ]]; then echo no value; fi
no value
```
### Example 2
```
typeset -gA help_files
help_files[kb]='knowledge base'
```

# ------ CODE SNIPPETS ------

## Code Snippets Large

## Code Snippets Small
### Ask question and read input
```
_warning "*** WARNING: This will re-install WordPress core files ***"
_warning "*** Please make sure this is the correct directory $1 ***"
read -q "REPLY?Continue? (y/n)"
```

### Run a command stored in a variable
* https://stackoverflow.com/questions/13665172/zsh-run-a-command-stored-in-a-variable
```
I believe you have two problems here - the first is that your install_cmd is being interpreted as a single string, instead of a command (sudo) with 3 arguments.

Your final attempt $=install_cmd actually does solve that problem correctly (though I'd write it as ${=install_cmd} instead), but then you hit your second problem: ~some_server/bin/do_install is not a known command. This is because sudo doesn't interpret the ~ like you intend, for safety reasons; it would need to evaluate its arguments using the shell (or do some special-casing for ~, which is really none of sudo's business), which opens up a whole can of worms that, understandably, sudo does its best to avoid.

That's also why it worked to do eval ${install_cmd} - because that's literally treating the whole string as a thing to be evaluated, possibly containing multiple commands (e.g. if install_cmd contained echo foo; sudo rm -rf / it would be happy to wipe your system).

You have to be the one to decide whether you want install_cmd to allow full shell semantics, including variable interpolation, path expansion, multiple commands, etc. or whether it should just expand the words out and run them as a single command.
```

### Colors
* PS1=$'\e[0;31m$ \e[0m'
* https://en.wikipedia.org/wiki/ANSI_escape_code

## Positional Arguments Command Line
### zparseopts
* https://xpmo.gitlab.io/post/using-zparseopts/
* -D removes all the matched options from the parameter list, (supporting requirement 7) 
* -E tells zparseopts to expect options and parameters to be mixed in (supporting requirement 1; without it, it will stop like getopts does).
* What I find nice about zparseopts is that semantics like overriding vs stacking flags can be defined in the command, rather than managed after parsing.
* Here is a stacking example: -v increases verbosity, and -q decreases it:

```
zparseopts -D -E - v+=flag_v -verbose+=flag_v q+=flag_q -quiet+=flag_q
(( verbosity = $#flag_v - $#flag_q ))
```

#### Example 1
```
zparseopts -D -E h=help -help=help t+:=title o+:=opts r=result -result=result a=arrow -arrow=arrow

title=$title[2]
opts=$opts[2]
result=$result[2]
arrow=$arrow[2]

IFS=$'\n' opts=($(echo "$opts" | tr "|" "\n"))
```
#### Example 2
```
# Resources:
# - https://xpmo.gitlab.io/post/using-zparseopts/
# - https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#index-zparseopts
#
# Features:
# - supports short and long flags (ie: -v|--verbose)
# - supports short and long key/value options (ie: -f <file> | --filename <file>)
# - does NOT support short and long key/value options with equals assignment (ie: -f=<file> | --filename=<file>)
# - supports short option chaining (ie: -vh)
# - everything after -- is positional even if it looks like an option (ie: -f)
# - once we hit an arg that isn't an option flag, everything after that is considered positional
function zparseopts_demo() {
  local flag_help flag_verbose
  local arg_filename=(myfile)  # set a default
  local usage=(
    "zparseopts_demo [-h|--help]"
    "zparseopts_demo [-v|--verbose] [-f|--filename=<file>] [<message...>]"
  )

  # -D pulls parsed flags out of $@
  # -E allows flags/args and positionals to be mixed, which we don't want in this example
  # -F says fail if we find a flag that wasn't defined
  # -M allows us to map option aliases (ie: h=flag_help -help=h)
  # -K allows us to set default values without zparseopts overwriting them
  # Remember that the first dash is automatically handled, so long options are -opt, not --opt
  zmodload zsh/zutil
  zparseopts -D -F -K -- \
    {h,-help}=flag_help \
    {v,-verbose}=flag_verbose \
    {f,-filename}:=arg_filename ||
    return 1

  [[ -z "$flag_help" ]] || { print -l $usage && return }
  if (( $#flag_verbose )); then
    print "verbose mode"
  fi

  echo "--verbose: $flag_verbose"
  echo "--filename: $arg_filename[-1]"
  echo "positional: $@"
}
```

## -- Functions
```
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
```

## Color
* https://en.wikipedia.org/wiki/ANSI_escape_code

## Uppercase Variable
* ```${var:u}```

## Output of Command to Arry
```
array_of_lines=("${(@f)$(my_command)}")
```

# Troubleshooting and Hour Wasting Errors
## Return 1 Problems
If you have a function with an if statement and other functions that rely on an accurate return value. Make sure that an if statement is not returning 1. If it is, it will cause the function to return 1 and other functions that rely on the return value will not work correctly.

Example 

```
[[ $QUIET == 0 ]] && cd $DIR
echo "Test"
```

If `$QUIET == 0` then and cd $DIR is succesful, then return 0 will occur. However, if `$QUIET == 1` and `echo "test"` is succesful, then return 1 will occur. I don't knopw why.