# Common Errors
## buster InRelease' changed its 'Suite' value from 'stable' to 'oldstable'
```
apt-get update --allow-releaseinfo-change
```

# Common Commands
## To see all possible upgrades, run a upgrade in verbose mode and (to be safe) with simulation
* apt-get -V -s upgrade