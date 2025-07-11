#$$# Nodejs and NPM
# Nodejs 
# Installing nodeJS via NVM (Best Way)
## Install nvm
```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
```
## Load nvm
```
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```
## Install Nodejs
```
nvm install --lts
```

# Installing Nodejs on Ubuntu
* https://github.com/nodesource/distributions?tab=readme-ov-file#debian-and-ubuntu-based-distributions
```
curl -sL https://deb.nodesource.com/setup_14.x | bash
sudo apt-get install python-software-properties
sudo apt-get install -y nodejs
```

# Managing Multiple Node Versions
```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
```