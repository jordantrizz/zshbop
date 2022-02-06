# ----------------------------
# -- Functions that are Tools!
# ----------------------------

# -- Linux Specific
findswap () { find /proc -maxdepth 2 -path "/proc/[0-9]*/status" -readable -exec awk -v FS=":" '{process[$1]=$2;sub(/^[ \t]+/,"",process[$1]);} END {if(process["VmSwap"] && process["VmSwap"] != "0 kB") printf "%10s %-30s %20s\n",process["Pid"],process["Name"],process["VmSwap"]}' '{}' \; | awk '{print $(NF-1),$0}' | sort -h | cut -d " " -f2- }

# -- Nginx
nginx-inc () { cat $1; grep '^.*[^#]include' $1 | awk {'print $2'} | sed 's/;\+$//' | xargs cat }
alias ngx404log="$ZSH_ROOT/bin/ngx404log.sh"

# -- Exim
eximcq () { exim -bp | exiqgrep -i | xargs exim -Mrm }

# -- curl
vh () { vh_run=$(curl --header "Host: $1" $2 --insecure -i | head -50);echo $vh_run }

# -- SSL
check_ssl () { echo | openssl s_client -showcerts -servername $1 -connect $1:443 2>/dev/null | openssl x509 -inform pem -noout -text }

# -- Software
vhwinfo () { wget --no-check-certificate https://github.com/rafa3d/vHWINFO/raw/master/vhwinfo.sh -O - -o /dev/null|bash }
csf-install () { cd /usr/src; rm -fv csf.tgz; wget https://download.configserver.com/csf.tgz; tar -xzf csf.tgz; cd csf; sh install.sh }
github-cli () { sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0; sudo apt-add-repository https://cli.github.com/packages; sudo apt update; sudo apt install gh }

# -- Git Repositories
repos () {
	declare -A GIT_REPOS
	GIT_REPOS[jordantrizz/gp-tools]="GridPane Tools by @Jordantrizz"
	GIT_REPOS[jordantrizz/github-markdown-toc]="Add markdown table of contents to README.md"
	GIT_REPOS[jordantrizz/cloudflare-cli]="Interface with Cloudflares API"	
	GIT_REPOS[lmtca/site24x7-custom-install]="Custom Site24x7 install"
	
	
	if [ ! $1 ]; then
		echo "--------------------------"
		echo "-- Popular Github Repos --"
		echo "--------------------------"
		echo ""
		echo "This command pulls down popular Github repositories."
		echo ""
		echo "To pull down a repo, simply type \"repo <reponame>\" and the repository will be installed into ZSHBOP/repos"
		echo ""
		echo "-- Repositories --"
		echo ""	
		for key value in ${(kv)GIT_REPOS}; do
			printf '%s\n' "  ${(r:40:)key} - $value"
		done			
		echo ""
	else
		echo "-- Start repo install --"
		if [ $1 ]; then
			echo " - Installing $1 repo"
				git -C $ZSH_ROOT/repos clone https://github.com/$1
		else
			echo "Uknown repo $1"
		fi 
	fi	
}


# -- Setup Apps

ubuntu-netselect () {
	mkdir ~/tmp
        wget http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_amd64.deb -P ~/tmp
        sudo dpkg -i ~/tmpnetselect_0.3.ds1-28+b1_amd64.deb
}

setup-automysqlbackup () {
        cd $ZSH_ROOT/bin/AutoMySQLBackup
        ./install
}

