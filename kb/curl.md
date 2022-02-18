# Using Curl
## Curl another host 
```
curl --header "Host: domain.ca" https://127.0.0.1 -k --head
```
## Show Headers
```
curl --head https://google.com
```
## Show Headers and Following Location
```
curl --head -L https://google.com
```
## Check SSL Certificate
```
curl -vvI https://google.com
```
## Set User Agent
curl -A "Better Uptime Bot Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36" https://google.com