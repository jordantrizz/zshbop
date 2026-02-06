# Post-deploy script for traefik
# This script runs after the template is copied to the container directory
# and is then removed from the deployed copy.

# acme.json must have restricted permissions for Let's Encrypt
chmod 600 "$DOCKSOFT_CONTAINERS/traefik/acme.json"
_loading3 "Set permissions 600 on acme.json"
