# Litespeed
## Server Status
* /tmp/lshttpd/.rtreport

## PHP Process Mode
* https://www.litespeedtech.com/support/wiki/doku.php/litespeed_wiki:php:process-mode?fbclid=IwAR3JeoNcDcQ9MT_rEzdzR2ri1Mcqzc0Nz4QntL2U8IitkJOqEMt3gRZF5kI
* ProcessGroup Mode default and best overall.

## Quick Fixes
### Scheduled Posts not Triggering
* Turn off WP-admin cache in Object caching, in the exclude section, add this to query string "doing_wp_cron"