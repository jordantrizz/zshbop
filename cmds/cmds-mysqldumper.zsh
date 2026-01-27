# ==============================================================================
# -- MySQL Dumper/Loader
# ==============================================================================
_debug " -- Loading ${(%):-%N}"

# =====================================
# -- mysqldumper-db
# =====================================
help_mysql[mysqldumper-db]='Dump a MySQL database using mydumper. Usage: mysqldumper-db [-d output-dir] database-name'
function mysqldumper-db() {
    local database output_dir

    zparseopts -D -E d:=output_dir -- "$@"

    database="$1"

    if [[ -z "$database" ]]; then
        _error "Usage: mysqldumper-db [-d output-dir] database-name"
        return 1
    fi

    if ! _cmd_exists mydumper; then
        _error "mydumper is not installed"
        return 1
    fi

    if [[ -z "$output_dir" ]]; then
        output_dir="${PWD}/${database}-$(date +%Y-%m-%d)"
    else
        output_dir="${output_dir[2]}"
    fi

    if [[ -d "$output_dir" ]]; then
        _error "Output directory already exists: $output_dir"
        return 1
    fi

    mkdir -p "$output_dir"

    _loading "Dumping database '$database' to '$output_dir'"

    if mydumper -B "$database" -o "$output_dir"; then
        _success "Database dumped successfully to $output_dir"
        return 0
    else
        _error "Failed to dump database"
        rm -rf "$output_dir"
        return 1
    fi
}

# =====================================
# -- mysqlloader-db
# =====================================
help_mysql[mysqlloader-db]='Load a MySQL database from a mydumper dump. Usage: mysqlloader-db dump-dir database-name'
function mysqlloader-db() {
    local dump_dir database

    dump_dir="$1"
    database="$2"

    if [[ -z "$dump_dir" ]] || [[ -z "$database" ]]; then
        _error "Usage: mysqlloader-db dump-dir database-name"
        return 1
    fi

    if ! _cmd_exists myloader; then
        _error "myloader is not installed"
        return 1
    fi

    if [[ ! -d "$dump_dir" ]]; then
        _error "Dump directory not found: $dump_dir"
        return 1
    fi

    _loading "Loading database '$database' from '$dump_dir'"

    if myloader -B "$database" -d "$dump_dir"; then
        _success "Database loaded successfully from $dump_dir"
        return 0
    else
        _error "Failed to load database"
        return 1
    fi
}
