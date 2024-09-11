# Common Commands
## Get Users to Domain Mapping
https://support.cpanel.net/hc/en-us/articles/4420396389399-How-do-I-list-all-domains-for-a-user-account-on-my-server
```
cat /etc/userdomains
```
## Get Domain to User Mapping API
```
uapi --output=jsonpretty --user=$user DomainInfo list_domains
```