#!/usr/bin/env zsh
# -----------------------------------------------------------------------------------
# -- checks-security.zsh -- Security hardening audit (hardcheck)
# -- Ubuntu-focused: SSH daemon, fail2ban, user accounts
# -----------------------------------------------------------------------------------
_debug " -- Loading ${(%):-%N}"

# ==================================================
# -- help_checks registration
# ==================================================
help_checks[hardcheck]='Security hardening audit (ssh, fail2ban, accounts, report)'

# ==================================================
# -- _security_require_ubuntu
# -- Guard: only run on Ubuntu. Returns 1 (skip) if not Ubuntu.
# ==================================================
function _security_require_ubuntu () {
    if [[ "$MACHINE_OS_FLAVOUR" != "ubuntu" ]]; then
        _log "hardcheck is currently Ubuntu-only (detected: $MACHINE_OS_FLAVOUR). Skipping."
        return 1
    fi
    return 0
}

# ==================================================
# -- _hardcheck_usage () - Print sub-command help
# ==================================================
function _hardcheck_usage () {
    echo "Usage: hardcheck [SUB-COMMAND] [OPTIONS]"
    echo ""
    echo "  Linux login and SSH hardening audit (Ubuntu)."
    echo ""
    echo "Sub-commands:"
    echo "  ssh         Audit SSH daemon configuration"
    echo "  fail2ban    Check fail2ban brute-force protection"
    echo "  accounts    Audit user accounts for login risks"
    echo "  report      Consolidated report with fix recommendations"
    echo "  (none)      Run all checks"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show detailed output"
    echo "  -h, --help      This message"
    echo ""
    return 0
}

# ==================================================
# -- hardcheck () - Main dispatcher
# ==================================================
function hardcheck () {
    local -a opts_help opts_verbose
    zparseopts -D -E -- h=opts_help -help=opts_help v=opts_verbose -verbose=opts_verbose

    # Set global verbose flag for sub-functions
    typeset -g _HARDCHECK_VERBOSE=0
    [[ ${#opts_verbose} -gt 0 ]] && typeset -g _HARDCHECK_VERBOSE=1

    _security_require_ubuntu || { unset _HARDCHECK_VERBOSE; return 0 }

    local sub="$1"
    [[ -n "$sub" ]] && shift

    # If -h was given, pass it along to the sub-command for specific help
    if [[ -n $opts_help ]]; then
        # Re-inject -h for the sub-function since zparseopts consumed it
        case "$sub" in
            ssh|fail2ban|accounts|report)
                _hardcheck_${sub} --help
                ;;
            ""|help)
                _hardcheck_usage
                ;;
            *)
                _error "Unknown sub-command: $sub"
                _hardcheck_usage
                ;;
        esac
        unset _HARDCHECK_VERBOSE
        return 0
    fi

    case "$sub" in
        ssh)
            _hardcheck_ssh "$@"
            ;;
        fail2ban)
            _hardcheck_fail2ban "$@"
            ;;
        accounts)
            _hardcheck_accounts "$@"
            ;;
        report)
            _hardcheck_report "$@"
            ;;
        "")
            _hardcheck_all "$@"
            ;;
        *)
            _error "Unknown sub-command: $sub"
            _hardcheck_usage
            unset _HARDCHECK_VERBOSE
            return 1
            ;;
    esac

    unset _HARDCHECK_VERBOSE
}

# ==================================================
# -- _hardcheck_all () - Run all checks in sequence
# ==================================================
function _hardcheck_all () {
    echo ""
    _loading "Running Security Hardening Checks..."
    echo ""

    local total_issues=0

    _hardcheck_ssh "$@"
    total_issues=$((total_issues + $?))

    _hardcheck_fail2ban "$@"
    total_issues=$((total_issues + $?))

    _hardcheck_accounts "$@"
    total_issues=$((total_issues + $?))

    _divider_dash " SUMMARY "
    if (( total_issues == 0 )); then
        _success "All security checks passed"
    else
        _warning "$total_issues security issue(s) found — run 'hardcheck report' for details"
    fi
    echo ""

    return $total_issues
}

# ==================================================
# -- _security_get_sshd_setting <setting>
# -- Reads a setting from sshd config, respecting Include drop-ins (Ubuntu 22.04+).
# -- Returns the *last* effective value (last match wins in sshd).
# ==================================================
function _security_get_sshd_setting () {
    local setting="$1"
    local value=""
    local config_files=()

    # Collect all config files: main + drop-ins
    if [[ -f /etc/ssh/sshd_config ]]; then
        config_files+=(/etc/ssh/sshd_config)
    fi
    if [[ -d /etc/ssh/sshd_config.d ]]; then
        config_files+=(/etc/ssh/sshd_config.d/*.conf(N))
    fi

    # Extract the LAST matching line (last match wins in sshd)
    local f v
    for f in "${config_files[@]}"; do
        v=$(grep -i "^\s*${setting}\s\+" "$f" 2>/dev/null | tail -1 | sed 's/^\s*[^ ]*\s\+//')
        if [[ -n "$v" ]]; then
            value="$v"
        fi
    done

    echo "$value"
}

# ==================================================
# -- _hardcheck_ssh () - Audit SSH daemon configuration
# ==================================================
function _hardcheck_ssh () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help

    if [[ -n $opts_help ]]; then
        echo "Usage: hardcheck ssh [-h|--help]"
        echo "  Audits /etc/ssh/sshd_config and drop-ins for security best practices."
        echo ""
        echo "  Checks: PasswordAuthentication, PubkeyAuthentication, PermitRootLogin,"
        echo "  ChallengeResponseAuthentication, PermitEmptyPasswords, X11Forwarding,"
        echo "  UsePAM, MaxAuthTries, LoginGraceTime, AllowUsers/AllowGroups."
        return 0
    fi

    _loading "SSH Daemon Configuration Audit"
    local issues=0
    local total=0

    # Helper: check a boolean setting (yes/no)
    _check_sshd_bool () {
        local setting="$1" expected="$2" desc="$3"
        ((total++))
        local actual=$(_security_get_sshd_setting "$setting")
        actual=${actual:l}  # lowercase
        if [[ "$actual" == "$expected" ]]; then
            _success "  $desc ($setting = $actual)"
        elif [[ -z "$actual" ]]; then
            _warning "  $desc ($setting is NOT SET — default may apply)"
            ((issues++))
        else
            _warning "  $desc ($setting = $actual, should be $expected)"
            ((issues++))
        fi
    }

    # Helper: check a numeric setting is ≤ max
    _check_sshd_max () {
        local setting="$1" max="$2" desc="$3"
        ((total++))
        local actual=$(_security_get_sshd_setting "$setting")
        if [[ -z "$actual" ]]; then
            _warning "  $desc ($setting is NOT SET)"
            ((issues++))
        elif [[ $actual -le $max ]]; then
            _success "  $desc ($setting = $actual, ≤ $max)"
        else
            _warning "  $desc ($setting = $actual, should be ≤ $max)"
            ((issues++))
        fi
    }

    # -- Core SSH hardening checks --
    _check_sshd_bool "PasswordAuthentication"         "no"   "Password authentication disabled"
    _check_sshd_bool "PubkeyAuthentication"            "yes"  "Public key authentication enabled"
    _check_sshd_bool "ChallengeResponseAuthentication" "no"   "Challenge-response auth disabled"
    _check_sshd_bool "PermitEmptyPasswords"            "no"   "Empty passwords rejected"
    _check_sshd_bool "X11Forwarding"                   "no"   "X11 forwarding disabled"
    _check_sshd_bool "UsePAM"                          "yes"  "PAM enabled (required for fail2ban)"

    # -- PermitRootLogin: "no" or "prohibit-password" are both acceptable --
    ((total++))
    local root_login=$(_security_get_sshd_setting "PermitRootLogin")
    root_login=${root_login:l}
    case "$root_login" in
        no|prohibit-password)
            _success "  Root login via SSH ($root_login)" ;;
        "")
            _warning "  Root login via SSH (PermitRootLogin NOT SET)"
            ((issues++)) ;;
        *)
            _warning "  Root login via SSH (PermitRootLogin = $root_login, should be no or prohibit-password)"
            ((issues++)) ;;
    esac

    # -- Numeric limits --
    _check_sshd_max "MaxAuthTries"   3  "Max auth tries ≤ 3"
    _check_sshd_max "LoginGraceTime" 60 "Login grace time ≤ 60s"

    # -- AllowUsers / AllowGroups (bonus: informational only) --
    local allow_users=$(_security_get_sshd_setting "AllowUsers")
    local allow_groups=$(_security_get_sshd_setting "AllowGroups")
    if [[ -n "$allow_users" || -n "$allow_groups" ]]; then
        _loading3 "  SSH access restricted: AllowUsers=$allow_users AllowGroups=$allow_groups"
    else
        _loading3 "  No AllowUsers/AllowGroups set — all valid users can attempt SSH"
    fi

    # -- Summary --
    if (( issues == 0 )); then
        _success "SSH daemon config: ALL $total CHECKS PASSED"
    else
        _warning "SSH daemon config: $issues/$total checks have issues"
    fi
    echo ""
    return $issues
}

# ==================================================
# -- _hardcheck_fail2ban () - Check fail2ban installation and SSH jail
# ==================================================
function _hardcheck_fail2ban () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help

    if [[ -n $opts_help ]]; then
        echo "Usage: hardcheck fail2ban [-h|--help]"
        echo "  Checks fail2ban installation, service status, and SSH jail configuration."
        echo ""
        echo "  Checks: package installed, service active/enabled, SSH jail configured,"
        echo "  fail2ban-client status, bantime and maxretry settings."
        return 0
    fi

    _loading "Fail2ban Brute-Force Protection Audit"
    local issues=0

    # -- 1. Is fail2ban installed? --
    if dpkg-query -l fail2ban &>/dev/null; then
        _success "  fail2ban package installed"
    else
        _warning "  fail2ban package NOT INSTALLED — brute force protection missing"
        echo ""
        return 1
    fi

    # -- 2. Is the service running? --
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        _success "  fail2ban service is running"
    else
        _warning "  fail2ban service is NOT running"
        ((issues++))
    fi

    # -- 3. Is the service enabled at boot? --
    if systemctl is-enabled --quiet fail2ban 2>/dev/null; then
        _success "  fail2ban service enabled at boot"
    else
        _warning "  fail2ban service NOT enabled at boot"
        ((issues++))
    fi

    # -- 4. Is there an SSH jail configured? --
    local sshd_jail=""
    # Check common locations for sshd jail config
    for f in /etc/fail2ban/jail.local /etc/fail2ban/jail.conf /etc/fail2ban/jail.d/*.conf(N); do
        if [[ -f "$f" ]] && grep -q '^\[sshd\]' "$f" 2>/dev/null; then
            sshd_jail="$f"
            break
        fi
    done

    if [[ -n "$sshd_jail" ]]; then
        local enabled
        enabled=$(grep -A10 '^\[sshd\]' "$sshd_jail" 2>/dev/null | grep -i '^\s*enabled\s*=' | tail -1 | awk -F= '{print $2}' | tr -d ' ')
        if [[ "${enabled:l}" == "true" || -z "$enabled" ]]; then
            _success "  SSH jail configured in $sshd_jail"
        else
            _warning "  SSH jail found in $sshd_jail but enabled = $enabled"
            ((issues++))
        fi
    else
        _warning "  No [sshd] jail found in fail2ban config"
        ((issues++))
    fi

    # -- 5. Check fail2ban-client for active sshd jail status --
    if (( $+commands[fail2ban-client] )); then
        if fail2ban-client status sshd &>/dev/null; then
            local banned
            banned=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
            _success "  SSH jail active — currently banned IPs: ${banned:-0}"
        else
            _warning "  SSH jail not active (fail2ban-client status sshd failed)"
            ((issues++))
        fi

        # -- 6. Show bantime and maxretry (informational) --
        local bantime maxretry
        bantime=$(fail2ban-client get sshd bantime 2>/dev/null)
        maxretry=$(fail2ban-client get sshd maxretry 2>/dev/null)
        [[ -n "$bantime" ]] && _loading3 "  SSH jail bantime: ${bantime}s  maxretry: ${maxretry}"
    fi

    # -- Summary --
    if (( issues == 0 )); then
        _success "Fail2ban: ALL CHECKS PASSED"
    else
        _warning "Fail2ban: $issues issue(s) found"
    fi
    echo ""
    return $issues
}

# ==================================================
# -- _hardcheck_accounts () - Audit user accounts for login risks
# ==================================================
function _hardcheck_accounts () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help

    if [[ -n $opts_help ]]; then
        echo "Usage: hardcheck accounts [-h|--help] [-v|--verbose]"
        echo "  Audits user accounts for login risks."
        echo ""
        echo "  Checks: empty passwords, locked accounts, UID 0 accounts,"
        echo "  sudo group membership, and passwordless sudo entries."
        echo ""
        echo "  Note: run with sudo to read /etc/shadow for full password state checks."
        return 0
    fi

    _loading "User Account Security Audit"
    local issues=0
    local has_shadow=0

    # -- Check we can read /etc/shadow --
    if [[ -r /etc/shadow ]]; then
        has_shadow=1
    else
        _warning "  /etc/shadow not readable — skipping password state checks (run with sudo)"
    fi

    # -- 1. Accounts with empty/locked passwords (requires /etc/shadow) --
    if (( has_shadow )); then
        _loading3 "  Checking for accounts with no password set..."
        local empty_pwds=()
        local locked=()
        local active=()
        while IFS=: read -r user passwd rest; do
            if [[ -z "$passwd" ]]; then
                empty_pwds+=("$user")
            elif [[ "$passwd" == "!" || "$passwd" == "!!" || "$passwd" == "*" ]]; then
                locked+=("$user")
            elif [[ "$passwd" == "!"* ]]; then
                locked+=("$user")
            else
                active+=("$user")
            fi
        done < /etc/shadow

        if (( ${#empty_pwds[@]} > 0 )); then
            _warning "  Accounts with EMPTY password (no password required to login):"
            for u in "${empty_pwds[@]}"; do
                _loading4 "    $u"
            done
            ((issues++))
        else
            _success "  No accounts with empty passwords"
        fi

        # -- 2. Locked vs active accounts with valid shells --
        _loading3 "  Locked (disabled) accounts: ${#locked[@]}"
        if (( _HARDCHECK_VERBOSE && ${#locked[@]} > 0 )); then
            local locked_list="${locked[*]}"
            _loading4 "    $locked_list"
        fi

        local shell_users=()
        for user in "${active[@]}"; do
            local shell
            shell=$(getent passwd "$user" 2>/dev/null | cut -d: -f7)
            if [[ -n "$shell" && "$shell" != "/usr/sbin/nologin" && "$shell" != "/bin/false" && "$shell" != "/sbin/nologin" && "$shell" != "/usr/bin/nologin" ]]; then
                shell_users+=("$user:$shell")
            fi
        done

        if (( ${#shell_users[@]} > 0 )); then
            _loading3 "  Accounts with passwords and valid shells (can login): ${#shell_users[@]}"
            if (( _HARDCHECK_VERBOSE )); then
                for entry in "${shell_users[@]}"; do
                    _loading4 "    $entry"
                done
            fi
        else
            _loading3 "  No accounts with passwords and valid shells"
        fi
    fi

    # -- 3. UID 0 accounts (should only be root) --
    _loading3 "  Checking for UID 0 accounts..."
    local uid0=()
    while IFS=: read -r user passwd uid rest; do
        if [[ "$uid" == "0" ]]; then
            uid0+=("$user")
        fi
    done < /etc/passwd

    if (( ${#uid0[@]} == 1 )) && [[ "${uid0[1]}" == "root" ]]; then
        _success "  Only root has UID 0"
    else
        local uid0_list="${uid0[*]}"
        _warning "  UID 0 accounts (should only be root): $uid0_list"
        ((issues++))
    fi

    # -- 4. Sudo group members --
    _loading3 "  Checking sudo group membership..."
    local sudoers=()
    if getent group sudo &>/dev/null; then
        local sudo_members
        sudo_members=$(getent group sudo | cut -d: -f4)
        if [[ -n "$sudo_members" ]]; then
            sudoers=(${(s:,:)sudo_members})
        fi
    fi

    if (( ${#sudoers[@]} > 0 )); then
        local sudoers_list="${sudoers[*]}"
        _loading3 "  Users in sudo group (can escalate to root): $sudoers_list"
    else
        _success "  No users in sudo group"
    fi

    # -- 5. Passwordless sudo entries --
    _loading3 "  Checking for passwordless sudo entries..."
    local nopasswd_issues=0

    if [[ -r /etc/sudoers ]]; then
        local nopasswd
        nopasswd=$(grep -v '^#' /etc/sudoers 2>/dev/null | grep -i "NOPASSWD" || true)
        if [[ -n "$nopasswd" ]]; then
            _warning "  Passwordless sudo entries in /etc/sudoers"
            ((nopasswd_issues++))
            if (( _HARDCHECK_VERBOSE )); then
                while IFS= read -r line; do
                    [[ -n "$line" ]] && _loading4 "    $line"
                done <<< "$nopasswd"
            fi
        fi
    fi

    if [[ -d /etc/sudoers.d ]]; then
        local nopasswd_d
        nopasswd_d=$(grep -r -v '^#' /etc/sudoers.d/ 2>/dev/null | grep -i "NOPASSWD" || true)
        if [[ -n "$nopasswd_d" ]]; then
            _warning "  Passwordless sudo entries in /etc/sudoers.d/"
            ((nopasswd_issues++))
            if (( _HARDCHECK_VERBOSE )); then
                while IFS= read -r line; do
                    [[ -n "$line" ]] && _loading4 "    $line"
                done <<< "$nopasswd_d"
            fi
        fi
    fi

    if (( nopasswd_issues == 0 )); then
        _success "  No passwordless sudo entries found"
    fi
    issues=$((issues + nopasswd_issues))

    # -- Summary --
    if (( issues == 0 )); then
        _success "User accounts: ALL CHECKS PASSED"
    else
        _warning "User accounts: $issues issue(s) found"
    fi
    echo ""
    return $issues
}

# ==================================================
# -- _hardcheck_report () - Consolidated report with fix recommendations
# ==================================================
function _hardcheck_report () {
    local -a opts_help
    zparseopts -D -E -- h=opts_help -help=opts_help

    if [[ -n $opts_help ]]; then
        echo "Usage: hardcheck report [-h|--help]"
        echo "  Runs all audits and prints a consolidated report with fix recommendations."
        return 0
    fi

    echo ""
    _divider_white " SECURITY HARDENING REPORT "
    echo ""
    _loading3 "Host: $(hostname) | OS: $MACHINE_OS_FLAVOUR $MACHINE_OS_VERSION | $(date)"
    echo ""

    local total_issues=0

    _hardcheck_ssh
    total_issues=$((total_issues + $?))

    _hardcheck_fail2ban
    total_issues=$((total_issues + $?))

    _hardcheck_accounts
    total_issues=$((total_issues + $?))

    _divider_dash " OVERALL VERDICT "
    if (( total_issues == 0 )); then
        _banner_green " ALL SECURITY CHECKS PASSED — Server is well hardened "
    else
        _banner_red " $total_issues SECURITY ISSUE(S) FOUND — Review warnings above "
    fi
    echo ""

    # -- Quick fix recommendations --
    if (( total_issues > 0 )); then
        _loading "Quick Fix Recommendations"
        echo ""
        echo "  1. Harden SSH daemon:"
        echo "     Edit /etc/ssh/sshd_config (or add a .conf file in /etc/ssh/sshd_config.d/):"
        echo "       PasswordAuthentication no"
        echo "       PubkeyAuthentication yes"
        echo "       PermitRootLogin prohibit-password"
        echo "       ChallengeResponseAuthentication no"
        echo "       UsePAM yes"
        echo "       X11Forwarding no"
        echo "       MaxAuthTries 3"
        echo "       LoginGraceTime 60"
        echo "     Then restart: sudo systemctl restart sshd"
        echo ""
        echo "  2. Install fail2ban:"
        echo "       sudo apt-get update && sudo apt-get install -y fail2ban"
        echo "       sudo systemctl enable --now fail2ban"
        echo "       sudo fail2ban-client set sshd bantime 3600"
        echo "       sudo fail2ban-client set sshd maxretry 3"
        echo ""
        echo "  3. Secure user accounts:"
        echo "       Lock unused accounts:  sudo passwd -l <username>"
        echo "       Remove empty passwords: sudo passwd -d <username>"
        echo "       Review sudoers:         sudo visudo"
        echo ""
    fi

    return $total_issues
}
