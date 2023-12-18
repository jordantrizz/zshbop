# Development
This is mostly for myself, but if someone else want's to contribute then this is a good place to start.

# Debugging
# Debug
Partialy implemented, but needs to be improved.
## Debugging Functions
You can use the function zbdebug on the cli and _debugf within any function to print out debug information.

```
zbdebug os-binary
** [DEBUG]: No binary specified
```

The function os-binary has a _debugf "No binary specified" which is printed out when zbdebug is called with the argument os-binary.

