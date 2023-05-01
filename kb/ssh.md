# Secure SSH Keys
```
ssh-keygen -t ed25519
```

# Public Key Login Only
```
PasswordAuthentication yes
PermitRootLogin prohibit-password
```

# Secure SSHD Logins
```
AllowUsers root user1 site1

# Restrict user to sftp and their own home directory
#CONFIG FOR USER=site1
#Match User site1
#        ForceCommand internal-sftp
#        ChrootDirectory /home/site1
#        PasswordAuthentication yes
#        X11Forwarding no
#        AllowTcpForwarding no
#ENDCONFIG FOR USER=site1
```