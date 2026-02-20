# ==============================================
# WHMCS commands
# ==============================================
_debug " -- Loading ${(%):-%N}"

help_files[whmcs]='WHMCS commands'
typeset -gA help_whmcs


# ===============================================
# -- _whmcs_parse_config
# ===============================================
_whmcs_parse_config () {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        _error "WHMCS config file not found: ${config_file}"
        return 1
    fi

    typeset -g WHMCS_DB_HOST WHMCS_DB_NAME WHMCS_DB_USER WHMCS_DB_PASS

    WHMCS_DB_HOST=$(sed -n "s/^[[:space:]]*\\\$db_host[[:space:]]*=[[:space:]]*['\"]\\([^'\"]*\\)['\"].*/\\1/p" "$config_file" | head -n1)
    WHMCS_DB_NAME=$(sed -n "s/^[[:space:]]*\\\$db_name[[:space:]]*=[[:space:]]*['\"]\\([^'\"]*\\)['\"].*/\\1/p" "$config_file" | head -n1)
    WHMCS_DB_USER=$(sed -n "s/^[[:space:]]*\\\$db_username[[:space:]]*=[[:space:]]*['\"]\\([^'\"]*\\)['\"].*/\\1/p" "$config_file" | head -n1)
    WHMCS_DB_PASS=$(sed -n "s/^[[:space:]]*\\\$db_password[[:space:]]*=[[:space:]]*['\"]\\([^'\"]*\\)['\"].*/\\1/p" "$config_file" | head -n1)

    if [[ -z "$WHMCS_DB_HOST" || -z "$WHMCS_DB_NAME" || -z "$WHMCS_DB_USER" || -z "$WHMCS_DB_PASS" ]]; then
        _error "Unable to parse DB credentials from ${config_file}"
        return 1
    fi

    return 0
}


# ===============================================
# -- _whmcs_mysql_exec
# ===============================================
_whmcs_mysql_exec () {
    local query="$1"
    mysql -h "$WHMCS_DB_HOST" -u "$WHMCS_DB_USER" -p"$WHMCS_DB_PASS" "$WHMCS_DB_NAME" -N -B -e "$query"
}


# ===============================================
# -- _whmcs_sql_escape
# ===============================================
_whmcs_sql_escape () {
    echo "$1" | sed "s/'/''/g"
}


# ===============================================
# -- _whmcs_validate_month
# ===============================================
_whmcs_validate_month () {
    local month="$1"
    if ! [[ "$month" =~ ^[0-9]{1,2}$ ]] || (( month < 1 || month > 12 )); then
        _error "MONTH must be 1-12"
        return 1
    fi

    return 0
}


# ===============================================
# -- _whmcs_validate_year
# ===============================================
_whmcs_validate_year () {
    local year="$1"
    if ! [[ "$year" =~ ^[0-9]{4}$ ]]; then
        _error "YEAR must be 4 digits (example: 2029)"
        return 1
    fi

    return 0
}


# ===============================================
# -- _whmcs_resolve_client_id
# ===============================================
_whmcs_resolve_client_id () {
    local client_id="$1"
    local email="$2"
    local escaped_email=""
    local resolved_client_id=""

    if [[ -n "$client_id" && -n "$email" ]]; then
        _error "Use either --id or --email, not both"
        return 1
    fi

    if [[ -n "$client_id" ]]; then
        if ! [[ "$client_id" =~ ^[0-9]+$ ]]; then
            _error "Client ID must be numeric"
            return 1
        fi
        echo "$client_id"
        return 0
    fi

    if [[ -n "$email" ]]; then
        if [[ "$email" != *"@"* ]]; then
            _error "Email appears invalid: ${email}"
            return 1
        fi

        escaped_email=$(_whmcs_sql_escape "$email")
        resolved_client_id=$(_whmcs_mysql_exec "SELECT id FROM tblclients WHERE email = '${escaped_email}' ORDER BY id DESC LIMIT 1;")
        if [[ -z "$resolved_client_id" ]]; then
            _warning "No client found for email: ${email}"
            return 1
        fi

        echo "$resolved_client_id"
        return 0
    fi

    _error "You must provide --id or --email"
    return 1
}


# ===============================================
# -- whmcs-expiry-get
# ===============================================
help_whmcs[whmcs-expiry-get]='List expiry data for one client (--id or --email)'
whmcs-expiry-get () {
    whmcs-expiry-get-usage () {
        echo "Usage: whmcs-expiry-get [-c <configuration.php>] (--id <client_id> | --email <email>)"
        echo ""
        echo "Options:"
        echo "  -c <file>      WHMCS configuration.php path (default: ./configuration.php)"
        echo "  -i <id>        WHMCS client ID"
        echo "  -e <email>     WHMCS client email"
        echo "  -h             Show help"
    }

    local -a ARG_CONFIG ARG_ID ARG_EMAIL ARG_HELP
    local config_file="./configuration.php"
    local client_id=""
    local email=""
    local resolved_client_id=""
    local escaped_email=""
    local client_count=""

    zparseopts -D -E c:=ARG_CONFIG i:=ARG_ID e:=ARG_EMAIL h=ARG_HELP -help=ARG_HELP

    [[ -n $ARG_HELP ]] && { whmcs-expiry-get-usage; return 0; }
    [[ -n $ARG_CONFIG ]] && config_file="$ARG_CONFIG[2]"
    [[ -n $ARG_ID ]] && client_id="$ARG_ID[2]"
    [[ -n $ARG_EMAIL ]] && email="$ARG_EMAIL[2]"

    _whmcs_parse_config "$config_file" || return 1

    resolved_client_id=$(_whmcs_resolve_client_id "$client_id" "$email") || return 1

    escaped_email=$(_whmcs_sql_escape "$email")
    if [[ -n "$client_id" ]]; then
        client_count=$(_whmcs_mysql_exec "SELECT COUNT(*) FROM tblclients WHERE id = ${resolved_client_id};")
    else
        client_count=$(_whmcs_mysql_exec "SELECT COUNT(*) FROM tblclients WHERE id = ${resolved_client_id} AND email = '${escaped_email}';")
    fi

    if [[ "$client_count" -eq 0 ]]; then
        _warning "No matching client found"
        return 1
    fi

    _loading "Client expiry details"
    echo "client_id\tfirstname\tlastname\temail\tpaymethod_id\tgateway\tpayment_type\tcard_type\tlast_four\texpiry_date"
    _whmcs_mysql_exec "
    SELECT
      c.id,
      c.firstname,
      c.lastname,
      c.email,
      COALESCE(pm.id, ''),
      COALESCE(pm.gateway_name, ''),
      COALESCE(pm.payment_type, ''),
      COALESCE(cc.card_type, ''),
      COALESCE(cc.last_four, ''),
      COALESCE(DATE_FORMAT(cc.expiry_date, '%Y-%m-%d %H:%i:%s'), '')
    FROM tblclients c
    LEFT JOIN tblpaymethods pm
      ON pm.userid = c.id
      AND pm.deleted_at IS NULL
    LEFT JOIN tblcreditcards cc
      ON cc.pay_method_id = pm.id
      AND cc.deleted_at IS NULL
    WHERE c.id = ${resolved_client_id}
    ORDER BY COALESCE(pm.order_preference, 0) DESC, pm.id DESC;
    "
}


# ===============================================
# -- whmcs-expiry-list
# ===============================================
help_whmcs[whmcs-expiry-list]='List all clients and expiry date from preferred pay method'
whmcs-expiry-list () {
    whmcs-expiry-list-usage () {
        echo "Usage: whmcs-expiry-list [-c <configuration.php>]"
        echo ""
        echo "Options:"
        echo "  -c <file>      WHMCS configuration.php path (default: ./configuration.php)"
        echo "  -h             Show help"
    }

    local -a ARG_CONFIG ARG_HELP
    local config_file="./configuration.php"

    zparseopts -D -E c:=ARG_CONFIG h=ARG_HELP -help=ARG_HELP

    [[ -n $ARG_HELP ]] && { whmcs-expiry-list-usage; return 0; }
    [[ -n $ARG_CONFIG ]] && config_file="$ARG_CONFIG[2]"

    _whmcs_parse_config "$config_file" || return 1

    _loading "Listing all clients and preferred card expiry"
    echo "client_id\tfirstname\tlastname\temail\tpaymethod_id\tgateway\tpayment_type\tcard_type\tlast_four\texpiry_date"
    _whmcs_mysql_exec "
    SELECT
      c.id,
      c.firstname,
      c.lastname,
      c.email,
      COALESCE(pm.id, ''),
      COALESCE(pm.gateway_name, ''),
      COALESCE(pm.payment_type, ''),
      COALESCE(cc.card_type, ''),
      COALESCE(cc.last_four, ''),
      COALESCE(DATE_FORMAT(cc.expiry_date, '%Y-%m-%d %H:%i:%s'), '')
    FROM tblclients c
    LEFT JOIN tblpaymethods pm
      ON pm.id = (
        SELECT pm2.id
        FROM tblpaymethods pm2
        WHERE pm2.userid = c.id
          AND pm2.deleted_at IS NULL
        ORDER BY COALESCE(pm2.order_preference, 0) DESC, pm2.id DESC
        LIMIT 1
      )
    LEFT JOIN tblcreditcards cc
      ON cc.id = (
        SELECT cc2.id
        FROM tblcreditcards cc2
        WHERE cc2.pay_method_id = pm.id
          AND cc2.deleted_at IS NULL
        ORDER BY cc2.updated_at DESC, cc2.id DESC
        LIMIT 1
      )
    ORDER BY c.id ASC;
    "
}


# ===============================================
# -- whmcs-expiry-set
# ===============================================
help_whmcs[whmcs-expiry-set]='Update WHMCS local credit card expiry for a client'
whmcs-expiry-set () {
    whmcs-expiry-set-usage () {
        echo "Usage: whmcs-expiry-set [-c <configuration.php>] (--id <client_id> | --email <email>) --year <yyyy> [--month <mm>]"
        echo ""
        echo "Options:"
        echo "  -c <file>      WHMCS configuration.php path (default: ./configuration.php)"
        echo "  -i <id>        WHMCS client ID"
        echo "  -e <email>     WHMCS client email"
        echo "  -y <year>      Expiry year (4 digits)"
        echo "  -m <month>     Expiry month (1-12, default: 10)"
        echo "  -h             Show help"
        echo ""
        echo "Notes:"
        echo "  - Updates WHMCS local expiry field only (tblcreditcards.expiry_date)."
        echo "  - Does not update card expiry at gateway provider."
    }

    local -a ARG_CONFIG ARG_ID ARG_EMAIL ARG_YEAR ARG_MONTH ARG_HELP
    local config_file="./configuration.php"
    local client_id=""
    local email=""
    local year=""
    local month="10"
    local resolved_client_id=""
    local paymethod_id=""
    local has_cc_row=""
    local last_day=""
    local new_expiry=""

    zparseopts -D -E c:=ARG_CONFIG i:=ARG_ID e:=ARG_EMAIL y:=ARG_YEAR m:=ARG_MONTH h=ARG_HELP -help=ARG_HELP

    [[ -n $ARG_HELP ]] && { whmcs-expiry-set-usage; return 0; }
    [[ -n $ARG_CONFIG ]] && config_file="$ARG_CONFIG[2]"
    [[ -n $ARG_ID ]] && client_id="$ARG_ID[2]"
    [[ -n $ARG_EMAIL ]] && email="$ARG_EMAIL[2]"
    [[ -n $ARG_YEAR ]] && year="$ARG_YEAR[2]"
    [[ -n $ARG_MONTH ]] && month="$ARG_MONTH[2]"

    if [[ -z "$year" ]]; then
        whmcs-expiry-set-usage
        _error "--year is required"
        return 1
    fi

    _whmcs_parse_config "$config_file" || return 1

    _whmcs_validate_year "$year" || return 1
    _whmcs_validate_month "$month" || return 1

    resolved_client_id=$(_whmcs_resolve_client_id "$client_id" "$email") || return 1

    paymethod_id=$(_whmcs_mysql_exec "
    SELECT pm.id
    FROM tblpaymethods pm
    WHERE pm.userid = ${resolved_client_id}
      AND pm.deleted_at IS NULL
    ORDER BY COALESCE(pm.order_preference, 0) DESC, pm.id DESC
    LIMIT 1;
    ")

    if [[ -z "$paymethod_id" ]]; then
        _error "No active pay method found for client ID: ${resolved_client_id}"
        return 1
    fi

    has_cc_row=$(_whmcs_mysql_exec "
    SELECT COUNT(*)
    FROM tblcreditcards
    WHERE pay_method_id = ${paymethod_id}
      AND deleted_at IS NULL;
    ")

    if [[ "$has_cc_row" -eq 0 ]]; then
        _error "No active tblcreditcards row found for paymethod_id=${paymethod_id}"
        return 1
    fi

    last_day="$(date -d "${year}-$(printf '%02d' "$month")-01 +1 month -1 day" +%d)"
    new_expiry="${year}-$(printf '%02d' "$month")-${last_day} 00:00:00"

    _loading "Before update"
    _whmcs_mysql_exec "
    SELECT cc.pay_method_id, cc.card_type, cc.last_four, DATE_FORMAT(cc.expiry_date, '%Y-%m-%d %H:%i:%s')
    FROM tblcreditcards cc
    WHERE cc.pay_method_id = ${paymethod_id}
      AND cc.deleted_at IS NULL
    ORDER BY cc.id DESC
    LIMIT 1;
    "

    _whmcs_mysql_exec "
    UPDATE tblcreditcards
    SET expiry_date = '${new_expiry}',
        updated_at = NOW()
    WHERE pay_method_id = ${paymethod_id}
      AND deleted_at IS NULL;
    "

    _loading "After update"
    _whmcs_mysql_exec "
    SELECT cc.pay_method_id, cc.card_type, cc.last_four, DATE_FORMAT(cc.expiry_date, '%Y-%m-%d %H:%i:%s')
    FROM tblcreditcards cc
    WHERE cc.pay_method_id = ${paymethod_id}
      AND cc.deleted_at IS NULL
    ORDER BY cc.id DESC
    LIMIT 1;
    "

    _success "Updated expiry_date for client ${resolved_client_id} (paymethod_id=${paymethod_id}) to ${new_expiry}"
}