# Install ZSH
## Make CentOS 6 ZSH 5.1.1
```
wget https://www.zsh.org/pub/old/zsh-5.1.1.tar.xz
tar --strip-components=1 -xvf zsh-5.1.1-doc.tar.xz
./Util/preconfig
./configure
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

# Debug ZSH
## ZSH Trace
```zsh -xv```
## ZSH Trace + Log
```zsh -xv 2> debug.err.txt``

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
* string = pattern
* string == pattern
* true if string matches pattern. The two forms are exactly equivalent. The ‘=’ form is the traditional shell syntax (and hence the only one generally used with the test and [ builtins); the ‘==’ form provides compatibility with other sorts of computer language.

* string != pattern
* true if string does not match pattern.
* string =~ regexp
* string -eq string

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

# Associatve Arrays
* See https://scriptingosx.com/2019/11/associative-arrays-in-zsh/
## Example 1
```
userinfo=( name armin shell zsh website scriptingosx.com )
userinfo=( [name]=armin [shell]=zsh [website]="scriptingosx.com" )
% userinfo=( [name]=beth [shell]=zsh )
% if [[ -z $userinfo[website] ]]; then echo no value; fi
no value
```
## Example 2
```
typeset -gA help_files
help_files[kb]='knowledge base'
``

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

# Ask question and read input
```
_warning "*** WARNING: This will re-install WordPress core files ***"
_warning "*** Please make sure this is the correct directory $1 ***"
read -q "REPLY?Continue? (y/n)"
```

# Run a command stored in a variable
* https://stackoverflow.com/questions/13665172/zsh-run-a-command-stored-in-a-variable
```
I believe you have two problems here - the first is that your install_cmd is being interpreted as a single string, instead of a command (sudo) with 3 arguments.

Your final attempt $=install_cmd actually does solve that problem correctly (though I'd write it as ${=install_cmd} instead), but then you hit your second problem: ~some_server/bin/do_install is not a known command. This is because sudo doesn't interpret the ~ like you intend, for safety reasons; it would need to evaluate its arguments using the shell (or do some special-casing for ~, which is really none of sudo's business), which opens up a whole can of worms that, understandably, sudo does its best to avoid.

That's also why it worked to do eval ${install_cmd} - because that's literally treating the whole string as a thing to be evaluated, possibly containing multiple commands (e.g. if install_cmd contained echo foo; sudo rm -rf / it would be happy to wipe your system).

You have to be the one to decide whether you want install_cmd to allow full shell semantics, including variable interpolation, path expansion, multiple commands, etc. or whether it should just expand the words out and run them as a single command.

```

# Add to array
```
ARRAY=()
ARRAY+=('foo')
ARRAY+=('bar')
```

# Colors
* PS1=$'\e[0;31m$ \e[0m'
* https://en.wikipedia.org/wiki/ANSI_escape_code

# Positional Arguments Command Line
* https://xpmo.gitlab.io/post/using-zparseopts/

Well, -D removes all the matched options from the parameter list, (supporting requirement 7) and -E tells zparseopts to expect options and parameters to be mixed in (supporting requirement 1; without it, it will stop like getopts does).

What I find nice about zparseopts is that semantics like overriding vs stacking flags can be defined in the command, rather than managed after parsing.

Here is a stacking example: -v increases verbosity, and -q decreases it:

zparseopts -D -E - v+=flag_v -verbose+=flag_v q+=flag_q -quiet+=flag_q
(( verbosity = $#flag_v - $#flag_q ))

```
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
```

# Color
* https://en.wikipedia.org/wiki/ANSI_escape_code

# Uppercase Variable
* ```${var:u}```
