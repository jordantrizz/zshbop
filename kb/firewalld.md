# Common Rules
```
firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='192.168.1.1' port port='7080' protocol='tcp' accept" --zone=public
```