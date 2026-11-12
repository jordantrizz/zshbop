---
title: Monit
description: "Knowledge base article on Monit. Also available in the shell as `kb monit`."
---

<!-- BEGIN GENERATED: kb-monit -->
### Update Monit on GridPAne
```
systemctl stop monit
cd /opt/gridpane/
wget https://mmonit.com/monit/dist/binary/5.27.0/monit-5.27.0-linux-x64.tar.gz
tar zxvf /opt/gridpane/monit-5.27.0-linux-x64.tar.gz
rm /opt/gridpane/monit-5.27.0-linux-x64.tar.gz
cp /opt/gridpane/monit-5.27.0/bin/monit /usr/local/bin/
# cp /etc/monit/monitrc /etc/ # Not required and breaks things
```

---

*Generated from [`kb/monit.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/monit.md) by
`npm run gen:kb`. The shell shows the same article with `kb monit`.*

<!-- END GENERATED: kb-monit -->
