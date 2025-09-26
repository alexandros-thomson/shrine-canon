#!/usr/bin/env bash
# Validate webhook_dlq column names and basic types.
# Usage: PSQL_BIN=/usr/bin/psql PGHOST=... PGUSER=... PGPASSWORD=... PGDATABASE=... ./validate_dlq_columns.sh
set -euo pipefail
PSQL_BIN="${PSQL_BIN:-psql}"
TABLE="${TABLE:-webhook_dlq}"

declare -A expected
expected[id]="serial integer bigint"
expected[payload]="jsonb"
expected[retry_count]="integer"
expected[last_error]="text"
expected[processed]="boolean"
expected[failed_at]="timestamp"
expected[payload_hash]="text"

rows="$($PSQL_BIN -tA -v ON_ERROR_STOP=1 -c "SELECT column_name || E'|' || data_type FROM information_schema.columns WHERE table_name='${TABLE}' ORDER BY ordinal_position;" 2>/dev/null || true)"
if [ -z "$rows" ]; then
  echo "ERROR: Table '${TABLE}' not found or inaccessible."
  exit 2
fi

declare -A found
while IFS=$'\n' read -r line; do
  col="$(printf '%s' "$line" | cut -d'|' -f1)"
  dtype="$(printf '%s' "$line" | cut -d'|' -f2-)"
  found["$col"]="$dtype"
done <<EOF
$rows
EOF

missing=()
mismatched=()
for col in "${!expected[@]}"; do
  if [ -z "${found[$col]:-}" ]; then
    missing+=("$col")
  else
    exp="${expected[$col]}"
    got="${found[$col]}"
    if [[ ! "$got" =~ ${exp%% *} ]]; then
      mismatched+=("$col: expected contains '${exp}', got '${got}'")
    fi
  fi
done

echo "Columns discovered:"
for k in "${!found[@]}"; do
  echo " - $k: ${found[$k]}"
done

if [ ${#missing[@]} -eq 0 ] && [ ${#mismatched[@]} -eq 0 ]; then
  echo "OK: webhook_dlq contains expected columns (basic types)."
  exit 0
fi

if [ ${#missing[@]} -gt 0 ]; then
  echo "MISSING:"
  for c in "${missing[@]}"; do echo " - $c"; done
fi
if [ ${#mismatched[@]} -gt 0 ]; then
  echo "MISMATCHED:"
  for m in "${mismatched[@]}"; do echo " - $m"; done
fi
exit 3
