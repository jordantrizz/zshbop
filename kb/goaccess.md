# Realtime Run
* goaccess /home/runcloud/logs/access.log -o report.html --log-format='"%v %h - - %^[%d:%t %^] "%r" %s %^"' --date-format=%d/%b/%Y --time-format=%T --real-time-html

# Custom Log Formats
## Runcloud Access Log Openlightspeed
```--log-format='"%v %h - - %^[%d:%t %^] "%r" %s %^"' --date-format=%d/%b/%Y --time-format=%T```
## GridPane