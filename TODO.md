# TODO

## Current

### Visual Studio Code Detect
* Print out a _loading3 "Detected Visual Studio Code shell"

### Code Comments
* Fix cmds-aws.zsh header.

### Error PVE
 * Checking System
init_check_services:5: no matches found: [pveversion]=pveversion 2>/dev/null

### WHMCS Update Expiry Date Command.
* Add in a way to list the expiry date for a client.
* Add in a way to list all clients and their expiry date.
* Get databse information from configuration file.
```
#!/usr/bin/env bash
set -euo pipefail

# Update WHMCS saved card expiry (Stripe RemoteCreditCard) by CLIENT_ID + EXPIRY YEAR
# Finds the client's Stripe RemoteCreditCard paymethod, then updates tblcreditcards.expiry_date.
#
# Usage:
#   ./whmcs_set_card_expiry.sh CLIENT_ID YEAR [MONTH]
#
# Examples:
#   ./whmcs_set_card_expiry.sh 112 2029
#   ./whmcs_set_card_expiry.sh 112 2029 10
#
# Notes:
# - This updates WHMCS's local expiry record only (tblcreditcards.expiry_date).
# - It does NOT update the expiry stored at Stripe.

DB_NAME="bill_billing"
DB_HOST="localhost"
DB_USER="whmcs_user"
DB_PASS="your_db_password"

CLIENT_ID="${1:-}"
YEAR="${2:-}"
MONTH="${3:-10}"   # default to October to match your earlier example

if [[ -z "$CLIENT_ID" || -z "$YEAR" ]]; then
  echo "Usage: $0 CLIENT_ID YEAR [MONTH]"
  exit 1
fi

if ! [[ "$CLIENT_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: CLIENT_ID must be numeric"
  exit 1
fi

if ! [[ "$YEAR" =~ ^[0-9]{4}$ ]]; then
  echo "Error: YEAR must be 4 digits (e.g. 2029)"
  exit 1
fi

if ! [[ "$MONTH" =~ ^[0-9]{1,2}$ ]] || (( MONTH < 1 || MONTH > 12 )); then
  echo "Error: MONTH must be 1-12"
  exit 1
fi

# Compute last day of month (GNU date; works on most Linux servers)
LAST_DAY="$(date -d "${YEAR}-$(printf '%02d' "$MONTH")-01 +1 month -1 day" +%d)"
NEW_EXPIRY="${YEAR}-$(printf '%02d' "$MONTH")-${LAST_DAY} 00:00:00"

mysql_cmd=(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B)

# Find the paymethod id for this client (Stripe RemoteCreditCard, not deleted)
PAYMETHOD_ID="$("${mysql_cmd[@]}" -e "
SELECT pm.id
FROM tblpaymethods pm
WHERE pm.userid = ${CLIENT_ID}
  AND pm.gateway_name = 'stripe'
  AND pm.payment_type = 'RemoteCreditCard'
  AND pm.deleted_at IS NULL
ORDER BY pm.order_preference DESC, pm.id DESC
LIMIT 1;
")"

if [[ -z "$PAYMETHOD_ID" ]]; then
  echo "Error: No Stripe RemoteCreditCard pay method found for userid=${CLIENT_ID}"
  exit 1
fi

echo "Client: ${CLIENT_ID}"
echo "Selected paymethod_id: ${PAYMETHOD_ID}"
echo "Target expiry_date: ${NEW_EXPIRY}"
echo

echo "Before:"
"${mysql_cmd[@]}" -e "
SELECT cc.pay_method_id, cc.card_type, cc.last_four, cc.expiry_date
FROM tblcreditcards cc
WHERE cc.pay_method_id = ${PAYMETHOD_ID}
  AND cc.deleted_at IS NULL
LIMIT 1;
" || true
echo

# Ensure a creditcard row exists
HAS_CC_ROW="$("${mysql_cmd[@]}" -e "
SELECT COUNT(*)
FROM tblcreditcards
WHERE pay_method_id = ${PAYMETHOD_ID}
  AND deleted_at IS NULL;
")"

if [[ "${HAS_CC_ROW}" -eq 0 ]]; then
  echo "Error: No tblcreditcards row found for pay_method_id=${PAYMETHOD_ID}"
  exit 1
fi

# Update expiry_date
"${mysql_cmd[@]}" -e "
UPDATE tblcreditcards
SET expiry_date = '${NEW_EXPIRY}',
    updated_at = NOW()
WHERE pay_method_id = ${PAYMETHOD_ID}
  AND deleted_at IS NULL;
"

echo "After:"
"${mysql_cmd[@]}" -e "
SELECT cc.pay_method_id, cc.card_type, cc.last_four, cc.expiry_date
FROM tblcreditcards cc
WHERE cc.pay_method_id = ${PAYMETHOD_ID}
  AND cc.deleted_at IS NULL
LIMIT 1;
"

echo
echo "Done."
```
## Testing

## Outstanding
