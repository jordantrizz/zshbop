# Regexp Examples
# Match code that isn't single line commented using hash #
```
^(?<!#)((\s*|)(?<!#)include .*;$)
```