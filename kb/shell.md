# Shell Redirection
In Unix-like operating systems, 2> and 1> are used for redirection. They refer to the two main output streams: standard output (stdout) and standard error (stderr).

* 1> or simply > redirects the standard output (stdout). For example, command > file.txt will take the standard output of command and write it to file.txt.

* 2> redirects the standard error (stderr). For example, command 2> error.txt will take the error output of command and write it to error.txt.

So, the main difference between 2> and 1> is the type of output they redirect. 1> redirects stdout, which is the "normal" output of a program, while 2> redirects stderr, which is where error messages are usually sent.

In Unix-like operating systems, 3> is used for redirection of custom file descriptors. By default, the shell provides three file descriptors:

0 for standard input (stdin)
1 for standard output (stdout)
2 for standard error (stderr)
However, you can use additional file descriptors like 3, 4, etc., for custom purposes. For example, you might want to redirect some output to a log file while also displaying it on the screen.

In the view-std function in your script, 3> is used to create a new file descriptor that can be used to redirect output. The 2>&3 part redirects stderr to this new file descriptor, and 3>&1 1>&2 swaps stdout and stderr. This allows the function to prepend "STDOUT: " and "STDERR: " to lines from stdout and stderr, respectively.

Here's a simplified example of how you might use 3>:

txt
This will redirect file descriptor 3 to log.txt. However, this won't do anything unless the command specifically writes to file descriptor 3.

## STDOUT OR STDERR
```
{ { command; } 2>&3 | sed 's/^/STDOUT: /'; } 3>&1 1>&2 | sed 's/^/STDERR: /'
```

## Redirect STDERR to STDOUT
```
ERROR=$(./useless.sh 2>&1 >/dev/null)
```

# Line Numbers on Output
``nl``
