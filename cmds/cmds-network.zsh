# --
# template commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[network]='Network tools and built-in scripts.'

# - Init help array
typeset -gA help_network

_debug " -- Loading ${(%):-%N}"

# -- paths
help_network[interfaces]='Print out network interfaces'
function interfaces () {
	if [[ $MACHINE_OS == "mac" ]]; then
		interfaces_mac
	else
		_interfaces_linux
	fi
}

# -- listen
help_network[listen]="Show all tcp/tcp6 ports listening"
function listen () {
	netstat -anp | grep 'LISTEN' | egrep 'tcp|tcp6'
}

# -- whatismyip
help_network[whatismyip]="Get current machines internet facing IP Addres"
function whatismyip () {
	dig @resolver1.opendns.com A myip.opendns.com +short -4
	dig @resolver1.opendns.com AAAA myip.opendns.com +short -6
}

# -- dhcp-lease-list
help_network[dhcp-lease-list]="List all DHCP leases, included with dhcpd"

# ==============================================================================
# -- network-ports-raw
# ==============================================================================
help_network[network-ports]="List all network ports via /proc/net/tcp"
function network-ports () {
	_loading "Network Ports via /proc/net/tcp"
	awk '$4 == "0A" { port=substr($2, index($2, ":")+1); print "Port:", strtonum("0x" port) }' /proc/net/tcp /proc/net/tcp6 2>/dev/null || awk '$4 == "0A" { port=substr($2, index($2, ":")+1); cmd="echo $((0x" port "))"; cmd | getline port; close(cmd); print "Port:", port }' /proc/net/tcp /proc/net/tcp6
}

# ===============================================
# -- ports
# ===============================================
help_network[ports]="List commonly used ports"
function ports () {
	_loading "Commonly Used Ports"
	typeset -A zb_ports
	zb_ports[21]="FTP"
	zb_ports[22]="SSH"
	zb_ports[23]="Telnet"
	zb_ports[25]="SMTP"
	zb_ports[53]="DNS"
	zb_ports[80]="HTTP"
	zb_ports[110]="POP3"
	zb_ports[143]="IMAP"
	zb_ports[443]="HTTPS"
	zb_ports[465]="SMTPS"
	zb_ports[587]="SMTP"
	zb_ports[993]="IMAPS"
	zb_ports[995]="POP3S"
	zb_ports[3306]="MySQL"
	zb_ports[5432]="PostgreSQL"
	# Proxmox
	zb_ports[8006]="Proxmox"
	# Cyberpanel
	zb_ports[8080]="HTTP"
	zb_ports[8090]="Cyberpanel"
	zb_ports[8443]="HTTPS"
	zb_ports[10000]="Webmin"
	zb_ports[10050]="Zabbix"
	zb_ports[11211]="Memcached"

	# Sort $zb_ports by key
	for key in ${(kn)zb_ports}; do
		echo "Port: $key - ${zb_ports[$key]}"
	done

}