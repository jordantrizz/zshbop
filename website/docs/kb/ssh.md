---
title: SSH
description: "Knowledge base article on SSH. Also available in the shell as `kb ssh`."
---

<!-- BEGIN GENERATED: kb-ssh -->
```
ssh-keygen -t ed25519
```

## Public Key Login Only
```
PasswordAuthentication yes
PermitRootLogin prohibit-password
```

## Secure SSHD Logins
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

---

*Generated from [`kb/ssh.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/ssh.md) by
`npm run gen:kb`. The shell shows the same article with `kb ssh`.*

<!-- END GENERATED: kb-ssh -->
