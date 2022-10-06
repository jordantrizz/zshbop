# Common Commands
## Check Backups Status
* duplicacy check -tabular | less
## Prune Bad Revisions
* I guess there was an aborted backup which left a lot of unreferenced chunks. You can run a prune job with options -exhaustive -dry-run to check for unreferenced chunks.
```
duplicacy prune -exhaustive -dry-run
``
