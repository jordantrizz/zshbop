# STDOUT OR STDERR
```
{ { command; } 2>&3 | sed 's/^/STDOUT: /'; } 3>&1 1>&2 | sed 's/^/STDERR: /'
```

# Redirect STDERR to STDOUT
```
ERROR=$(./useless.sh 2>&1 >/dev/null)
```

# Line Numbers on Output
``nl``
