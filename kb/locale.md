# Perl Local Error
```
❯ perl
perl: warning: Setting locale failed.
perl: warning: Please check that your locale settings:
        LANGUAGE = "en_US.UTF-8",
        LC_ALL = "en_US.UTF-8",
        LANG = "C.UTF-8"
    are supported and installed on your system.
perl: warning: Falling back to a fallback locale ("C.UTF-8").
```
Try
```
locale-gen en_US en_US.UTF-8
```