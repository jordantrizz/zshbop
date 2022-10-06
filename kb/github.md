# Github CLI
* Install https://github.com/cli/cli/blob/trunk/docs/install_linux.md
## Install on Linux
* Note, the key below has changed due to the older one expirying.
```
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 23F3D4EA75716059
sudo apt-add-repository https://cli.github.com/packages
sudo apt update
sudo apt install gh
```

## Posting Gists
```
gh gist create /usr/local/bin/gphourlyworker -d "gphourlyworker fix"
```

## Posting Releases
```
gh release create 0.2.4a
```