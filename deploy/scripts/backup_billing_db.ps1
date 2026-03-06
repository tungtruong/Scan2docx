Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..\..")

$dbPath = if ($env:BACKUP_DB_PATH) { $env:BACKUP_DB_PATH } else { Join-Path $projectRoot "data\billing.sqlite3" }
$backupDir = if ($env:BACKUP_DIR) { $env:BACKUP_DIR } else { Join-Path $projectRoot "backups" }
$keepCount = if ($env:BACKUP_KEEP_COUNT) { $env:BACKUP_KEEP_COUNT } else { "14" }

python (Join-Path $scriptDir "backup_billing_db.py") --db-path $dbPath --backup-dir $backupDir --keep-count $keepCount
