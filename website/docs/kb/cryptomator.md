---
title: Cryptomator
description: "Knowledge base article on Cryptomator. Also available in the shell as `kb cryptomator`."
---

<!-- BEGIN GENERATED: kb-cryptomator -->
### Ubuntu
#### GUI
```
sudo add-apt-repository ppa:sebastian-stenzel/cryptomator
sudo apt update
```
#### CLI
```
apt install openjdk-17-jdk openjdk-17-jre libfuse2
cd $HOME/bin
wget https://github.com/cryptomator/cli/releases/download/0.5.1/cryptomator-cli-0.5.1.jar
```

```
sudo mkdir ~/mnt/vault
java -jar $HOME/bin/cryptomator-cli-0.5.1.jar --vault vault=/mnt/d/cryptomator-default/ --fusemount vault=$HOME/mnt/vault
```

---

*Generated from [`kb/cryptomator.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/cryptomator.md) by
`npm run gen:kb`. The shell shows the same article with `kb cryptomator`.*

<!-- END GENERATED: kb-cryptomator -->
