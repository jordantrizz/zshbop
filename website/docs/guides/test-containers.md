---
title: Test containers
description: Disposable Ubuntu containers for testing zshbop and its installer without touching the host.
---

A throwaway Ubuntu container is the cheapest way to test the installer or a change to the shell
without risking the host.

## A reusable container

```bash
docker pull ubuntu:jammy
docker create -it --name zshbop ubuntu:jammy
docker start zshbop
docker exec -it zshbop bash
```

## A one-time run

```bash
docker run -it ubuntu bash
```

## LXD on Ubuntu 22

```bash
apt install lxd-installer
lxd init
```

## Launching containers

LXD images are useful when you want several distributions at once:

```bash
lxc launch images:ubuntu/bionic/amd64 ubuntu-bionic
lxc launch images:ubuntu/focal/amd64 ubuntu-focal
lxc launch images:ubuntu/jammy/amd64 ubuntu-jammy
```

## See also

- [Testing](../contributing/testing.md) — the automated test scripts.
- [Installation](../getting-started/installation.md) — the installer these containers exercise.
