# Common Commands
* docker ps - show docker containers
* docker logs <container> - show container logs
* docker kill <container> - kill container
# Docker Compose
## Common Commands
* docker-compose up -d - Bring up containers or restart modified containers.

# Installation
## Docker Install on Ubuntu 22
```
apt-get remove docker docker-engine docker.io containerd runc
apt-get update
apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```
## Docker Compose
```
apt-get install docker-compose
```


# Portainer
## Install
```
docker volume create portainer_data
docker volume inspect portainer_data
docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
```

# Alpine
## Adding SSH for AWS EKR
* Start Docker Image
```docker run -it --entrypoint /bin/sh aab84910c0be```
* Add SSH
```
docker run -it --entrypoint /bin/sh aab84910c0be
apk add --no-cache sudo bash openrc openssh
mkdir -p /run/openrc && \
    touch /run/openrc/softlevel && \
    rc-update add sshd default
ssh-keygen -A
rc-service sshd start
```
* Exit and commit
```
docker ps -a
docker commit 6d79a83d645b aab84910c0be
```