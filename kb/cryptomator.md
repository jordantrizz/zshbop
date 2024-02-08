# Install Cryptomator
## Ubuntu
### GUI
```
sudo add-apt-repository ppa:sebastian-stenzel/cryptomator
sudo apt update
```
### CLI
```
apt install openjdk-17-jdk openjdk-17-jre libfuse2
cd $HOME/bin
wget https://github.com/cryptomator/cli/releases/download/0.5.1/cryptomator-cli-0.5.1.jar
```

```
sudo mkdir ~/mnt/vault
java -jar $HOME/bin/cryptomator-cli-0.5.1.jar --vault vault=/mnt/d/cryptomator-default/ --fusemount vault=$HOME/mnt/vault
```