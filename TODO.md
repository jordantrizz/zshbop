# TODO

## Current

### Error PVE
 * Checking System
init_check_services:5: no matches found: [pveversion]=pveversion 2>/dev/null

### README.md revamp and Documentation
* Look at keeping README.md slim and moving all documentation elsehwere.
* Whats a good method to provide documentation so it's pleasant to read and navigate on github.

## Testing
* whmcs commands

## Future

### Code Comments in cmd files.
* Look in all cmd files and make sure the header is formated as follows.
```
# =============================================================================
# -- AWS
# =============================================================================
_debug " -- Loading ${(%):-%N}"
help_files[aws]="AWS Commands and scripts"
typeset -gA help_aws
```

