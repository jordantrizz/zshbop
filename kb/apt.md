# Common Errors
## buster InRelease' changed its 'Suite' value from 'stable' to 'oldstable'
```
apt-get update --allow-releaseinfo-change
```
# Common Commands

## Show Package Details
```apt-get show <package>```

## Get Source Package
```apt-get source {pkg1}```

## To see all possible upgrades, run a upgrade in verbose mode and (to be safe) with simulation
* apt-get -V -s upgrade

## What Package Provides File
* ```dpkg -S /usr/bin/passwd```
* ```apt-file search vim```
* ```dpkg-query -S '/usr/sbin/useradd'```

## Don't install recommendations
* ```apt-get install --no-install-recommends```

Edit /etc/apt/apt.conf
```
APT::Install-Recommends "false";
APT::Install-Suggests "false";
```