# Display all errors
```journalctl -p 3 -xb```

* -p 3 means priority err
* -x provides extra message information
* -b means since last boot
# Display all Messages for a specific service
```journalctl -u service-name```
# Display all Messages for a specific service since last boot
```journalctl -u service-name -b```