#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: mysql-dump-extract.sh --source dump.sql --table my_table [--row 42] [--id 494] [--col-index 1] [--mode list|extract] [--output row_id.sql]

What it does:
  - Streams a mysqldump, finds INSERTs for a single table, and splits extended inserts into single rows.
  - Shows first and last row (by dump order) plus total row count.
  - Optionally extracts a specific row number (1-based) into row_id.sql.
  - Or, match by a column value (e.g., primary key) via --id/--match-value and --col-index.

Options:
  --source, -s   Path to mysqldump file (plain .sql or .gz)
  --table,  -t   Table name to inspect
  --row,    -r   Row number (1-based) to extract; if omitted you will be prompted
  --id           Convenience alias for --match-value when targeting column 1
  --match-value  Value to match in the selected column (takes precedence over --row)
  --col-index    1-based column index to match against (default: 1)
  --mode,   -m   "list" (default) prints summary; "extract" will prompt if --row is not provided
  --output, -o   Output file for extracted row (default: row_id.sql)
  --help,   -h   Show this help
EOF
}

SOURCE=""
TABLE=""
ROW=""
MODE="list"
OUTPUT="row_id.sql"
MATCH_VALUE=""
MATCH_COL_IDX="1"

while [ $# -gt 0 ]; do
  case "$1" in
    --source|-s)
      SOURCE=${2-}; shift 2 ;;
    --table|-t)
      TABLE=${2-}; shift 2 ;;
    --row|-r)
      ROW=${2-}; shift 2 ;;
    --id)
      MATCH_VALUE=${2-}; shift 2 ;;
    --match-value)
      MATCH_VALUE=${2-}; shift 2 ;;
    --col-index)
      MATCH_COL_IDX=${2-}; shift 2 ;;
    --mode|-m)
      MODE=${2-}; shift 2 ;;
    --output|-o)
      OUTPUT=${2-}; shift 2 ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage; exit 1 ;;
  esac
done

if [ -z "$SOURCE" ] || [ -z "$TABLE" ]; then
  echo "Missing required --source or --table" >&2
  usage
  exit 1
fi

case "$MATCH_COL_IDX" in
  ''|*[!0-9]*)
    echo "--col-index must be a positive integer" >&2
    exit 1 ;;
  0)
    echo "--col-index must be >= 1" >&2
    exit 1 ;;
esac

if [ ! -f "$SOURCE" ]; then
  echo "Source file not found: $SOURCE" >&2
  exit 1
fi

python3 - "$SOURCE" "$TABLE" "$MODE" "$ROW" "$OUTPUT" "$MATCH_VALUE" "$MATCH_COL_IDX" <<'PY'
import gzip
import re
import sys

source, table, mode, row_arg, output, match_value, match_col_idx_arg = sys.argv[1:8]
mode = (mode or "list").lower()
row_num = int(row_arg) if row_arg else None
match_value = match_value or None
match_col_idx = int(match_col_idx_arg or "1")


def stream_lines(path):
    if path.endswith('.gz'):
        with gzip.open(path, 'rt', encoding='utf-8', errors='replace') as fh:
            for line in fh:
                yield line
    else:
        with open(path, 'r', encoding='utf-8', errors='replace') as fh:
            for line in fh:
                yield line


def split_tuples(blob):
    tuples = []
    buf = []
    depth = 0
    in_str = False
    escape = False
    quote = None
    for ch in blob:
        if escape:
            buf.append(ch)
            escape = False
            continue
        if ch == '\\':
            buf.append(ch)
            escape = True
            continue
        if in_str:
            buf.append(ch)
            if ch == quote:
                in_str = False
            continue
        if ch in ("'", '"'):
            buf.append(ch)
            in_str = True
            quote = ch
            continue
        if ch == '(':
            depth += 1
            buf.append(ch)
            continue
        if ch == ')':
            depth -= 1
            buf.append(ch)
            if depth == 0:
                tuples.append(''.join(buf).strip())
                buf = []
            continue
        if ch == ',' and depth == 0:
            continue
        if ch == ';' and depth == 0:
            continue
        buf.append(ch)
    return tuples


def iter_rows(path, table_name):
    pattern = re.compile(
        rf"^(INSERT INTO [`\"]?{re.escape(table_name)}[`\"]?(?:\s*\([^)]+\))?\s+VALUES\s+)",
        re.IGNORECASE,
    )
    buffer = None
    header = None
    for line in stream_lines(path):
        if buffer is None:
            match = pattern.match(line)
            if not match:
                continue
            header = match.group(1)
            buffer = line[match.end():]
        else:
            buffer += line
        if buffer is not None and ';' in line:
            chunk = buffer
            buffer = None
            for row in split_tuples(chunk):
                yield header, row


def strip_quotes(val: str) -> str:
    val = val.strip()
    if len(val) >= 2 and val[0] == val[-1] and val[0] in ("'", '"'):
        return val[1:-1]
    return val


def column_value(row: str, col_idx: int):
    body = row.strip()
    if body.startswith('(') and body.endswith(')'):
        body = body[1:-1]
    buf = []
    in_str = False
    escape = False
    quote = None
    depth = 0
    idx = 1
    for ch in body:
        if escape:
            buf.append(ch)
            escape = False
            continue
        if ch == '\\':
            buf.append(ch)
            escape = True
            continue
        if in_str:
            buf.append(ch)
            if ch == quote:
                in_str = False
            continue
        if ch in ("'", '"'):
            buf.append(ch)
            in_str = True
            quote = ch
            continue
        if ch == '(':
            depth += 1
            buf.append(ch)
            continue
        if ch == ')':
            depth -= 1
            buf.append(ch)
            continue
        if ch == ',' and depth == 0 and not in_str:
            if idx == col_idx:
                return strip_quotes(''.join(buf))
            idx += 1
            buf = []
            continue
        buf.append(ch)
    if idx == col_idx:
        return strip_quotes(''.join(buf))
    return None


def extract_by_value(path, table_name, col_idx, target):
    for header, row in iter_rows(path, table_name):
        val = column_value(row, col_idx)
        if val == target:
            return f"{header}{row};\n"
    return None


def summarize(path, table_name):
    total = 0
    first = None
    last = None
    first_header = None
    first_col = None
    last_col = None
    for header, row in iter_rows(path, table_name):
        total += 1
        if first is None:
            first = row
            first_header = header
            first_col = column_value(row, match_col_idx)
        last = row
        last_col = column_value(row, match_col_idx)
    return total, first_header, first, last, first_col, last_col


def extract_row(path, table_name, target_idx):
    for idx, (header, row) in enumerate(iter_rows(path, table_name), start=1):
        if idx == target_idx:
            return f"{header}{row};\n"
    return None


total, header, first_row, last_row, first_col, last_col = summarize(source, table)

if total == 0:
    print(f"No INSERT rows found for table '{table}' in {source}")
    sys.exit(1)


def preview(row):
    if row is None:
        return "<not found>"
    row_flat = ' '.join(row.split())
    return row_flat[:180] + (' …' if len(row_flat) > 180 else '')


print(f"Table: {table}")
print(f"Total rows in dump order: {total}")
print(f"First row: {preview(first_row)}")
print(f"Last row:  {preview(last_row)}")
print(f"Column {match_col_idx} first value: {first_col}")
print(f"Column {match_col_idx} last value:  {last_col}")

if mode == 'list':
    sys.exit(0)

if match_value:
    row_num = None
elif row_num is None:
    try:
        entered = input("Enter row number to extract (1-based, blank to cancel): ").strip()
        if not entered:
            print("No row selected; exiting.")
            sys.exit(0)
        row_num = int(entered)
    except (EOFError, ValueError):
        print("Invalid input; exiting.")
        sys.exit(1)

if match_value:
    sql = extract_by_value(source, table, match_col_idx, match_value)
    if sql is None:
        print(f"Value '{match_value}' not found in column {match_col_idx} for table {table}.")
        sys.exit(1)
    print(f"Matched column {match_col_idx} value '{match_value}' -> writing to {output}")
else:
    if row_num is None:
        print("No row number provided; exiting.")
        sys.exit(1)
    if row_num < 1 or row_num > total:
        print(f"Row number {row_num} is out of range (1..{total}).")
        sys.exit(1)

    sql = extract_row(source, table, row_num)
    if sql is None:
        print(f"Could not locate row {row_num} in {source} for table {table}.")
        sys.exit(1)

with open(output, 'w', encoding='utf-8') as fh:
    fh.write(sql)

if match_value:
    print(f"Wrote matched row (col {match_col_idx} = {match_value}) to {output}")
else:
    print(f"Wrote row {row_num} to {output}")
PY
