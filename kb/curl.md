# Using Curl
## Curl Hostname bypassing DNS
### Method #1 - non-SNI
* ```curl --header "Host: domain.ca" https://127.0.0.1 -k --head```
* ```curl --header "Host: domain.ca" https://127.0.0.1 --head -k -v 2>&1 | grep subject```

### Method #2 - SNI Method
* https://stackoverflow.com/questions/50279275/curl-how-to-specify-target-hostname-for-https-request
* ```curl --resolve domain.ca:443:127.0.0.1 https://domain.ca --head -k -vvv 2>&1 | grep subject

### Method #3 - Get SSL subject only
* ```curl --resolve domain.ca:443:127.0.0.1 https://domain.ca --head -k -vvv 2>&1 | grep subject```

## Show Headers
### Simple
```
curl --head https://google.com
```
### Show Headers and Following Location
```
curl --head -L https://google.com
```
## Check SSL Certificate
```
curl -vvI https://google.com
```
## Set User Agent
curl -A "Better Uptime Bot Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36" https://google.com

## Curl Post
```curl -X POST https://testing.com```

## Download File to Specific Location
```curl -L "https://github.com/Neo23x0/signature-base/archive/refs/tags/v2.0.zip" --output $YARA_SIG_TMP/signature-base-2.0.zip```