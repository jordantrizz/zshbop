# Install netdata
```
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
```

# Specify different temporary directory, instead of default /tmp
```
env TMPDIR=/root/tmp bash <(curl -Ss https://my-netdata.io/kickstart.sh)
```