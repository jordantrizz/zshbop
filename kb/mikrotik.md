# DHCP
## DNS Search
* https://jjjordan.github.io/dhcp119/
```
/ip dhcp-server option add code=119 name=domain-search value="0x08'domain'0x03'com'0x00"
/ip dhcp-server option sets add name=domain-search-set options=domain-search
/ip dhcp-server set 0 dhcp-option-set=domain-search-set
```

# SSH
## SSH Issues
If you can't login with a password after adding an SSH key.
```
/ip ssh set always-allow-password-login=yes
```
## Import SSH Key
```
scp id_rsa.pub admin@192.168.80.1:.
ssh admin@192.168.80.1
/user ssh-keys import public-key-file=id_rsa.pub user=admin
```