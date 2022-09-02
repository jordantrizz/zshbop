# Speedtest.net CLI
* You can find all the guides at https://www.speedtest.net/apps/cli

# Installation
## macOS
```
brew tap teamookla/speedtest
brew update
# Example how to remove conflicting or old versions using brew
# brew uninstall speedtest --force
brew install speedtest --force
```
## Ubuntu/Debian
### If migrating from prior bintray install instructions please first...
```
sudo rm /etc/apt/sources.list.d/speedtest.list
sudo apt-get update
sudo apt-get remove speedtest
### Other non-official binaries will conflict with Speedtest CLI Example how to remove using apt-get
```
sudo apt-get remove speedtest-cli
sudo apt-get install curl
curl -s https://install.speedtest.net/app/cli/install.deb.sh | sudo bash
sudo apt-get install speedtest
```