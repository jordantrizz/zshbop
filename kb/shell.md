# STDOUT OR STDERR
```
{ { command; } 2>&3 | sed 's/^/STDOUT: /'; } 3>&1 1>&2 | sed 's/^/STDERR: /'
```