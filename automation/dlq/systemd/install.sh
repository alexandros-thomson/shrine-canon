#!/usr/bin/env bash
# Installer for dlq-handler systemd unit & timer and environment file template.
# Usage: sudo ./install.sh
set -euo pipefail
PKG_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="/etc/systemd/system"
ENV_DIR="/etc/temple"
ENV_TEMPLATE="${PKG_DIR}/../ledger.env.template"
ENV_DEST="${ENV_DIR}/ledger.env"
SERVICE_FILE="${PKG_DIR}/dlq-handler.service"
TIMER_FILE="${PKG_DIR}/dlq-handler.timer"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo)"; exit 2; }

for f in "$SERVICE_FILE" "$TIMER_FILE" "$ENV_TEMPLATE"; do
  if [ ! -f "$f" ]; then
    echo "Missing required file: $f"
    exit 3
  fi
done

if ! id -u temple >/dev/null 2>&1; then
  echo "Creating system user 'temple' (no-login)"
  useradd --system --no-create-home --shell /usr/sbin/nologin temple || true
fi

mkdir -p "$ENV_DIR"
chown root:temple "$ENV_DIR"
chmod 0750 "$ENV_DIR"

if [ -f "$ENV_DEST" ]; then
  echo "Environment file exists at ${ENV_DEST}; leaving intact."
else
  echo "Installing environment template to ${ENV_DEST}"
  cp -a "$ENV_TEMPLATE" "$ENV_DEST"
  chown root:temple "$ENV_DEST"
  chmod 0640 "$ENV_DEST"
fi

backup_and_copy() {
  local src="$1"; local dest="$2"
  if [ -e "$dest" ]; then
    echo "Backing up existing $dest -> ${dest}.bak.${TIMESTAMP}"
    cp -a "$dest" "${dest}.bak.${TIMESTAMP}"
  fi
  echo "Installing $src -> $dest"
  cp -a "$src" "$dest"
  chown root:root "$dest"
  chmod 0644 "$dest"
}

backup_and_copy "$SERVICE_FILE" "${TARGET_DIR}/dlq-handler.service"
backup_and_copy "$TIMER_FILE" "${TARGET_DIR}/dlq-handler.timer"

systemctl daemon-reload
systemctl enable --now dlq-handler.timer || true

echo "Installer finished. Verify with:"
echo "  systemctl status dlq-handler.timer"
echo "  journalctl -u dlq-handler.service -n 200 -f"
echo "Ensure /usr/local/bin/dlq_handler.sh exists and is executable and /etc/temple/ledger.env contains correct values."
