# Enable EPEL repository on AWS Linux
```amazon-linux-extras install epel -y```

# Troubleshoot EPEL Issues
* yum repolist

# Enable EPEL on AL1 
* yum install epel-release
* Double check /etc/yum/repos.d for enabled=1

# Get OS version
```cat /etc/os-release```