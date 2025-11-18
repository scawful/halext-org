#!/bin/bash
set -euo pipefail

# Copies an existing private/public key pair into the halext user’s SSH directory.
# Usage: sudo ./scripts/copy-ssh-key-to-halext.sh /path/to/key [halext] [id_ed25519]

KEY_PATH="${1:-}"
TARGET_USER="${2:-halext}"
TARGET_NAME="${3:-id_ed25519}"

if [[ -z "$KEY_PATH" ]]; then
  echo "Usage: $0 /path/to/key [user] [target-key-name]"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "This script must run as root so it can change ownership."
  exit 1
fi

if ! id "$TARGET_USER" >/dev/null 2>&1; then
  echo "User '$TARGET_USER' does not exist."
  exit 1
fi

if [[ ! -f "$KEY_PATH" ]]; then
  echo "Key '$KEY_PATH' does not exist."
  exit 1
fi

if ! command -v ssh-keygen >/dev/null 2>&1; then
  echo "ssh-keygen is required but not installed."
  exit 1
fi

TARGET_HOME="$(eval echo "~$TARGET_USER")"
TARGET_DIR="$TARGET_HOME/.ssh"
PRIV_DEST="$TARGET_DIR/$TARGET_NAME"
PUB_SOURCE="${KEY_PATH}.pub"
PUB_DEST="${PRIV_DEST}.pub"

mkdir -p "$TARGET_DIR"
chmod 700 "$TARGET_DIR"

install -m 600 "$KEY_PATH" "$PRIV_DEST"

if [[ -f "$PUB_SOURCE" ]]; then
  install -m 644 "$PUB_SOURCE" "$PUB_DEST"
else
  ssh-keygen -y -f "$KEY_PATH" >"$PUB_DEST"
  chmod 644 "$PUB_DEST"
fi

chown -R "$TARGET_USER":"$TARGET_USER" "$TARGET_DIR"

echo "SSH key copied to $TARGET_USER:$PRIV_DEST (public key at $PUB_DEST)."
