#!/usr/bin/env bash
# Taken from https://community.cloudflare.com/t/auto-update-ip-cloudflare-whitelist-in-my-server-with-csf/81641

IPS=`curl -s https://www.cloudflare.com/ips-v4`
IPS+=`echo -e "\n" && curl -s https://www.cloudflare.com/ips-v6`

for ip in ${IPS}; do
  sudo csf -a $ip
done

sudo csf -r