# Install
```
cd /usr/local/src
wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
tar -xzvf maldetect-current.tar.gz
cd maldetect-1.5
./install.sh
```
# ClamAV Install
```
yum -y install clamav clamav-deve
```
# Configure ClamAV
* Edit /usr/local/maldetect/conf.maldet and add
* Change value to '1' on line 114
```
scan_clamscan="1"
```

# Common Commands
* Updated Engine
```maldet -d && maldet -u```
* Scan Directory
```
maldet -a /var/www/html
```
* List Reporst
```
maldet --report list
```