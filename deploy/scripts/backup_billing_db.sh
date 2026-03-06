#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DB_PATH="${BACKUP_DB_PATH:-$PROJECT_ROOT/data/billing.sqlite3}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT/backups}"
KEEP_COUNT="${BACKUP_KEEP_COUNT:-14}"

python3 "$SCRIPT_DIR/backup_billing_db.py" \
  --db-path "$DB_PATH" \
  --backup-dir "$BACKUP_DIR" \
  --keep-count "$KEEP_COUNT"
