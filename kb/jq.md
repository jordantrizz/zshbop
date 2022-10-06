# jq Cheetsheets
* https://lzone.de/cheat-sheet/jq

# jq + tsv aka tables
Using the @tsv filter has much to recommend it, mainly because it handles numerous "edge cases" in a standard way:

```.[] | [.id, .name] | @tsv```

Adding the headers can be done like so:

```jq -r '["ID","NAME"], ["--","------"], (.[] | [.id, .name]) | @tsv'```