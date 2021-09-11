# Github CLI
* Install https://github.com/cli/cli/blob/trunk/docs/install_linux.md
## Install on Linux
```sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
sudo apt-add-repository https://cli.github.com/packages
sudo apt update
sudo apt install gh```

## Posting Gists
```
gh gist create /usr/local/bin/gphourlyworker -d "gphourlyworker fix"
```

## Posting Releases
```
gh release create 0.2.4a
```