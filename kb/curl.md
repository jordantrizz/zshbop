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