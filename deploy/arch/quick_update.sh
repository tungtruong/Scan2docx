#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Please run as root: sudo bash deploy/arch/quick_update.sh"
  exit 1
fi

INSTALL_DIR="${INSTALL_DIR:-/opt/scan2docx}"
SERVICE_NAME="${SERVICE_NAME:-scan2docx}"
APP_USER="${APP_USER:-scan2docx}"
BRANCH="${BRANCH:-master}"

if command -v pacman >/dev/null 2>&1; then
  pacman -Sy --noconfirm --needed \
    git python python-pip tesseract \
    base-devel gcc pkgconf \
    libjpeg-turbo zlib libtiff lcms2 libwebp openjpeg2 freetype2
fi

GIT_BIN="$(command -v git || true)"
if [[ -z "$GIT_BIN" ]]; then
  echo "git not found. Please install git (pacman -S git)."
  exit 1
fi

if [[ ! -d "$INSTALL_DIR/.git" ]]; then
  echo "No git repository at $INSTALL_DIR"
  exit 1
fi

if [[ ! -x "$INSTALL_DIR/.venv/bin/python" ]]; then
  echo "Missing python venv at $INSTALL_DIR/.venv"
  exit 1
fi

DB_PATH="${DB_PATH:-$INSTALL_DIR/data/billing.sqlite3}"
BACKUP_DIR="${BACKUP_DIR:-$INSTALL_DIR/backups}"
if [[ -f "$DB_PATH" ]]; then
  mkdir -p "$BACKUP_DIR"
  TS="$(date +%Y%m%d_%H%M%S)"
  cp "$DB_PATH" "$BACKUP_DIR/billing_preupdate_${TS}.sqlite3"
fi

runuser -u "$APP_USER" -- "$GIT_BIN" -C "$INSTALL_DIR" fetch origin "$BRANCH"
runuser -u "$APP_USER" -- "$GIT_BIN" -C "$INSTALL_DIR" checkout "$BRANCH"
runuser -u "$APP_USER" -- "$GIT_BIN" -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH"
runuser -u "$APP_USER" -- "$INSTALL_DIR/.venv/bin/pip" install --upgrade pip setuptools wheel
runuser -u "$APP_USER" -- "$INSTALL_DIR/.venv/bin/pip" install --prefer-binary -r "$INSTALL_DIR/requirements.txt"
runuser -u "$APP_USER" -- "$INSTALL_DIR/.venv/bin/python" -m compileall "$INSTALL_DIR/bot.py"

systemctl restart "${SERVICE_NAME}.service"
systemctl --no-pager --full status "${SERVICE_NAME}.service" | sed -n '1,20p'

echo "Update complete."
