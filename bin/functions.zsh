ultb_install () {
        sudo apt install python3-pip npm
        sudo pip install ngxtop
        npm install -g cloudflare-cli
}

ubuntu-netselect () {
	wget http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_amd64.deb
	sudo dpkg -i netselect_0.3.ds1-28+b1_amd64.deb
}

setup-automysqlbackup () {
	cd $ULTB/AutoMySQLBackup
	./install
}