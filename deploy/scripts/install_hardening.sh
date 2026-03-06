#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

PROJECT_ROOT="${1:-/opt/scan2docx}"
SERVICE_DIR="/etc/systemd/system"
F2B_FILTER_DIR="/etc/fail2ban/filter.d"
F2B_JAIL_DIR="/etc/fail2ban/jail.d"

echo "Installing hardening files from: $PROJECT_ROOT"

install -m 0644 "$PROJECT_ROOT/deploy/systemd/scan2docx.service" "$SERVICE_DIR/scan2docx.service"
install -m 0644 "$PROJECT_ROOT/deploy/systemd/scan2docx-backup.service" "$SERVICE_DIR/scan2docx-backup.service"
install -m 0644 "$PROJECT_ROOT/deploy/systemd/scan2docx-backup.timer" "$SERVICE_DIR/scan2docx-backup.timer"

systemctl daemon-reload
systemctl enable --now scan2docx.service
systemctl enable --now scan2docx-backup.timer

if [[ -d /etc/fail2ban ]]; then
  install -d "$F2B_FILTER_DIR" "$F2B_JAIL_DIR"
  install -m 0644 "$PROJECT_ROOT/deploy/fail2ban/filter.d/scan2docx-nginx.conf" "$F2B_FILTER_DIR/scan2docx-nginx.conf"
  install -m 0644 "$PROJECT_ROOT/deploy/fail2ban/jail.d/scan2docx-nginx.local" "$F2B_JAIL_DIR/scan2docx-nginx.local"

  if systemctl is-enabled fail2ban >/dev/null 2>&1 || systemctl is-active fail2ban >/dev/null 2>&1; then
    systemctl restart fail2ban
  fi
else
  echo "fail2ban not found, skipping fail2ban configuration."
fi

echo "Hardening install complete."
