-- Safe, idempotent migration to add helpful columns to webhook_dlq
BEGIN;

ALTER TABLE webhook_dlq ADD COLUMN IF NOT EXISTS payload_hash TEXT;
ALTER TABLE webhook_dlq ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ;
ALTER TABLE webhook_dlq ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- Backfill created_at from failed_at if missing
UPDATE webhook_dlq
SET created_at = failed_at
WHERE created_at IS NULL AND failed_at IS NOT NULL;

COMMIT;