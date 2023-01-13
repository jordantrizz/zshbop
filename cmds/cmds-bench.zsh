# --
# Benchmarking commands
#
# Example help: help_wordpress[wp]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[bench]='Benchmarking commands'

# - Init help array
typeset -gA help_bench

# -- speedtest-cli - find what's using swap.
help_bench[speedtest-cli]='Speedtest'
