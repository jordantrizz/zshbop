# Docker
## Docker Ubuntu Image for Testing
```
docker pull ubuntu:jammy
docker create -it --name zshbop ubuntu:jammy
docker start zshbop
```

## Docker Ubuntu Image One Time Run
```
docker run -it ubuntu bash
```

# Linux Container
## Setting up LXD on Ubuntu 22
```
 apt install lxd-installer
 lxd init
```
## Lauch Ubuntu 22 Container
```
lxc launch images:ubuntu/bionic/amd64 ubuntu-bionic
lxc launch images:ubuntu/focal/amd64 ubuntu-focal
lxc launch images:ubuntu/jammy/amd64 ubuntu-jammy
```
