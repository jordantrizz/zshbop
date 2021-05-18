# Using Curl
## Curl another host 
```
curl --head "Host: domain.com" --head https://127.0.0.1/
```
## Show Headers
```
curl --head https://google.com
```
## Show Headers and Following Location
```
curl --head -L https://google.com
```