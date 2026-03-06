#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Please run as root: sudo bash deploy/arch/install_arch_service.sh <repo_url_optional>"
  exit 1
fi

REPO_URL="${1:-}"
INSTALL_DIR="${INSTALL_DIR:-/opt/scan2docx}"
APP_USER="${APP_USER:-scan2docx}"
APP_GROUP="${APP_GROUP:-scan2docx}"
SERVICE_NAME="${SERVICE_NAME:-scan2docx}"
BRANCH="${BRANCH:-main}"

PYTHON_BIN="$(command -v python3 || true)"
if [[ -z "$PYTHON_BIN" ]]; then
  PYTHON_BIN="$(command -v python || true)"
fi
if [[ -z "$PYTHON_BIN" ]]; then
  echo "Python not found. Please install python (pacman -S python)."
  exit 1
fi

GIT_BIN="$(command -v git || true)"
if [[ -z "$GIT_BIN" ]]; then
  echo "git not found. Please install git (pacman -S git)."
  exit 1
fi

if command -v pacman >/dev/null 2>&1; then
  pacman -Sy --noconfirm --needed \
    git python python-pip tesseract \
    base-devel gcc pkgconf \
    libjpeg-turbo zlib libtiff lcms2 libwebp openjpeg2 freetype2
fi

if ! id -u "$APP_USER" >/dev/null 2>&1; then
  useradd --system --create-home --home-dir /var/lib/$APP_USER --shell /usr/bin/nologin "$APP_USER"
fi

if ! getent group "$APP_GROUP" >/dev/null 2>&1; then
  groupadd --system "$APP_GROUP"
fi

usermod -a -G "$APP_GROUP" "$APP_USER" >/dev/null 2>&1 || true

mkdir -p "$INSTALL_DIR"
chown -R "$APP_USER:$APP_GROUP" "$INSTALL_DIR"

if [[ -n "$REPO_URL" ]]; then
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    runuser -u "$APP_USER" -- "$GIT_BIN" -C "$INSTALL_DIR" fetch origin "$BRANCH"
    runuser -u "$APP_USER" -- "$GIT_BIN" -C "$INSTALL_DIR" checkout "$BRANCH"
    runuser -u "$APP_USER" -- "$GIT_BIN" -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH"
  else
    rm -rf "$INSTALL_DIR"
    runuser -u "$APP_USER" -- "$GIT_BIN" clone --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
  fi
fi

if [[ ! -f "$INSTALL_DIR/requirements.txt" ]]; then
  echo "Missing requirements.txt in $INSTALL_DIR. Clone/copy project first."
  exit 1
fi

if [[ ! -d "$INSTALL_DIR/.venv" ]]; then
  runuser -u "$APP_USER" -- "$PYTHON_BIN" -m venv "$INSTALL_DIR/.venv"
fi

runuser -u "$APP_USER" -- "$INSTALL_DIR/.venv/bin/pip" install --upgrade pip setuptools wheel
runuser -u "$APP_USER" -- env PIP_PREFER_BINARY=1 "$INSTALL_DIR/.venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt"

if [[ ! -f "$INSTALL_DIR/.env" ]]; then
  cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  chown "$APP_USER:$APP_GROUP" "$INSTALL_DIR/.env"
  chmod 600 "$INSTALL_DIR/.env"
  echo "Created $INSTALL_DIR/.env from template. Please edit BOT_TOKEN before start."
fi

install -m 0644 "$INSTALL_DIR/deploy/systemd/scan2docx-arch.service" "/etc/systemd/system/${SERVICE_NAME}.service"
sed -i "s|User=scan2docx|User=$APP_USER|g" "/etc/systemd/system/${SERVICE_NAME}.service"
sed -i "s|Group=scan2docx|Group=$APP_GROUP|g" "/etc/systemd/system/${SERVICE_NAME}.service"
sed -i "s|/opt/scan2docx|$INSTALL_DIR|g" "/etc/systemd/system/${SERVICE_NAME}.service"

systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}.service"

echo "Install complete."
echo "Service status: systemctl status ${SERVICE_NAME}.service"
echo "Quick update command: sudo INSTALL_DIR=$INSTALL_DIR SERVICE_NAME=$SERVICE_NAME BRANCH=$BRANCH bash $INSTALL_DIR/deploy/arch/quick_update.sh"
