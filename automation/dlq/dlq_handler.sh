#!/usr/bin/env bash
# hardened DLQ handler (automation/dlq/dlq_handler.sh)
# - Processes webhook_dlq rows
# - Attempts to replay via Redis (dedup via payload_hash SET NX)
# - Falls back to DB-backed enqueue into webhook_jobs (payload_hash based)
# - Marks processed or increments retry_count and records last_error
#
# Configure via /etc/temple/ledger.env (or env) - see README.md for variables
set -euo pipefail
IFS=$'\n\t'

# Config (defaults can be overridden via env)
PSQL_BIN="${PSQL_BIN:-/usr/bin/psql}"
DLQ_TABLE="${DLQ_TABLE:-webhook_dlq}"
DLQ_ID_COL="${DLQ_ID_COL:-id}"
DLQ_PAYLOAD_COL="${DLQ_PAYLOAD_COL:-payload}"
DLQ_PROCESSED_COL="${DLQ_PROCESSED_COL:-processed}"
DLQ_RETRY_COL="${DLQ_RETRY_COL:-retry_count}"
DLQ_CREATED_COL="${DLQ_CREATED_COL:-failed_at}"
DLQ_MAX_ATTEMPTS="${DLQ_MAX_ATTEMPTS:-5}"
BATCH_SIZE="${BATCH_SIZE:-100}"
LOG_DIR="${LOG_DIR:-/var/log/temple}"
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-}"
REDIS_URL="${REDIS_URL:-redis://localhost:6379/0}"
ROLE_SYNC_QUEUE="${ROLE_SYNC_QUEUE:-role_sync}"
DEDUP_TTL="${DEDUP_TTL:-3600}"

TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
LOG="${LOG_DIR}/dlq-handler-$(date +%F).log"
mkdir -p "$LOG_DIR"
touch "$LOG"
chmod 640 "$LOG" || true

log() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG"; }

push_metric() {
  local name="$1"; local value="$2"
  if [ -n "$PUSHGATEWAY_URL" ] && command -v curl >/dev/null 2>&1; then
    printf "%s %s\n" "$name" "$value" | curl --fail --silent --show-error --data-binary @- "${PUSHGATEWAY_URL}/metrics/job/dlq-handler" >/dev/null 2>&1 || {
      log "WARN: failed push metric ${name}"
    }
  fi
}

# Compute sha256 of payload (POSIX)
payload_hash() {
  printf '%s' "$1" | sha256sum | awk '{print $1}'
}

# Attempt replay: Redis first (via Python helper), then DB fallback.
# Returns:
#   0 on success (including duplicate-detected)
#   1 on failure (neither Redis nor DB accepted)
attempt_replay() {
  local id="$1"
  local payload="$2"
  local ph
  ph="")(payload_hash "$payload")"

  # try Redis path (python small helper returns exit code 0 ok, 2 redis-failed)
  if command -v python3 >/dev/null 2>&1; then
    PY_EXIT=0
    python3 - "$payload" "$ph" "$REDIS_URL" "$ROLE_SYNC_QUEUE" "$DEDUP_TTL" <<'PY' || PY_EXIT=$?
import sys, os, json, hashlib
try:
    from redis import Redis
except Exception:
    # signal redis failure to caller
    sys.exit(2)
payload = sys.argv[1]
payload_hash = sys.argv[2]
redis_url = sys.argv[3]
queue = sys.argv[4]
ttl = int(sys.argv[5])
try:
    r = Redis.from_url(redis_url, socket_timeout=5, socket_connect_timeout=5)
    dedup_key = f"role_sync_dedup:{payload_hash}"
    was_set = r.set(dedup_key, "1", nx=True, ex=ttl)
    if was_set:
        r.rpush(queue, payload)
    # success (including duplicate)
    sys.exit(0)
except Exception:
    sys.exit(2)
PY
    if [ "$PY_EXIT" -eq 0 ]; then
      return 0
    fi
  fi

  # Fallback: insert into webhook_jobs if payload_hash not present
  if command -v "$PSQL_BIN" >/dev/null 2>&1; then
    # base64 encode payload to safely pass into SQL
    local payload_b64
    payload_b64="$(printf '%s' "$payload" | base64 -w0)"
    # Check existing job
    local exists
    exists="$($PSQL_BIN -tA -v ON_ERROR_STOP=1 -c "SELECT id FROM webhook_jobs WHERE payload_hash = '$ph' LIMIT 1;" 2>/dev/null || true)"
    if [ -n "$exists" ]; then
      # duplicate -> treat as success
      return 0
    fi
    # Insert job decoding base64 -> convert_from(decode(...),'UTF8')::jsonb
    if "$PSQL_BIN" -v ON_ERROR_STOP=1 -c "INSERT INTO webhook_jobs (audit_id, payload, payload_hash, created_at, status) VALUES ('$id', convert_from(decode('$payload_b64','base64'),'UTF8')::jsonb, '$ph', now(), 'pending');" >/dev/null 2>&1; then
      return 0
    fi
  fi

  return 1
}

mark_processed() {
  local id="$1"; local note="${2:-processed}"
  "$PSQL_BIN" -v ON_ERROR_STOP=1 -c "UPDATE ${DLQ_TABLE} SET ${DLQ_PROCESSED_COL} = true, ${DLQ_RETRY_COL} = COALESCE(${DLQ_RETRY_COL},0) + 1, last_error = $$${note}$$, updated_at = now() WHERE ${DLQ_ID_COL} = ${id};" >/dev/null 2>&1 || {
    log "ERROR: mark_processed failed for id=${id}"
  }
}

mark_failed() {
  local id="$1"; local err="$2"
  "$PSQL_BIN" -v ON_ERROR_STOP=1 -c "UPDATE ${DLQ_TABLE} SET ${DLQ_RETRY_COL} = COALESCE(${DLQ_RETRY_COL},0) + 1, last_error = $$${err}$$, updated_at = now() WHERE ${DLQ_ID_COL} = ${id};" >/dev/null 2>&1 || {
    log "ERROR: mark_failed failed for id=${id}"
  }
}

# Fetch batch
SQL="SELECT ${DLQ_ID_COL} || E'\t' || ${DLQ_PAYLOAD_COL}::text FROM ${DLQ_TABLE} WHERE ${DLQ_PROCESSED_COL} = false AND COALESCE(${DLQ_RETRY_COL},0) < ${DLQ_MAX_ATTEMPTS} ORDER BY ${DLQ_CREATED_COL} ASC LIMIT ${BATCH_SIZE};"
rows="$($PSQL_BIN -tA -v ON_ERROR_STOP=1 -c "$SQL" 2>/dev/null || true)"
if [ -z "$rows" ]; then
  log "No DLQ rows to process."
  exit 0
fi

processed_count=0
failed_count=0

while IFS=$'\t' read -r id payload_text; do
  [ -z "$id" ] && continue
  log "Attempting replay id=${id}"
  if attempt_replay "$id" "$payload_text"; then
    log "Replay succeeded for id=${id}"
    mark_processed "$id" "replayed_successfully"
    processed_count=$((processed_count + 1))
  else
    log "Replay FAILED for id=${id}"
    mark_failed "$id" "replay_failed"
    failed_count=$((failed_count + 1))
  fi
done <<EOF
$rows
EOF

push_metric "dlq_processed_count" "${processed_count}"
push_metric "dlq_failed_count" "${failed_count}"
log "Batch complete processed=${processed_count} failed=${failed_count}"
# rotate logs older than 30 days
find "$LOG_DIR" -name "dlq-handler-*.log" -type f -mtime +30 -print -delete 2>/dev/null || true
