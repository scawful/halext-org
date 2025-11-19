#!/bin/bash
# Harden ownership and migrate responsibilities from the legacy 'justin' user
# to the 'halext' service account.
set -euo pipefail

TARGET_USER="${TARGET_USER:-halext}"
LEGACY_USER="${LEGACY_USER:-justin}"
REPO_ROOT="${REPO_ROOT:-/srv/halext.org/halext-org}"
WWW_ROOT="${WWW_ROOT:-/www}"
EXTRA_PATHS=${EXTRA_PATHS:-"/srv/halext.org"}

if [[ $EUID -ne 0 ]]; then
  echo "Run this script with sudo/root." >&2
  exit 1
fi

require_user() {
  local user="$1"
  if ! id "$user" >/dev/null 2>&1; then
    echo "User '$user' does not exist." >&2
    exit 1
  fi
}

require_user "$TARGET_USER"
TARGET_GROUP="$(id -gn "$TARGET_USER")"

if [[ -n "$LEGACY_USER" ]] && id "$LEGACY_USER" >/dev/null 2>&1; then
  echo "Locking legacy account '$LEGACY_USER' (passwd lock + nologin shell)..."
  passwd -l "$LEGACY_USER" >/dev/null
  usermod -s /usr/sbin/nologin "$LEGACY_USER"
fi

echo "Adding $TARGET_USER to useful groups (adm,www-data,sudo if missing)..."
for grp in adm www-data sudo; do
  if getent group "$grp" >/dev/null; then
    usermod -aG "$grp" "$TARGET_USER"
  fi
done

echo "Ensuring $TARGET_USER owns repo + www content..."
chown -R "$TARGET_USER":"$TARGET_GROUP" "$REPO_ROOT"
if [[ -d "$WWW_ROOT" ]]; then
  chown -R "$TARGET_USER":"$TARGET_GROUP" "$WWW_ROOT"
fi
for path in $EXTRA_PATHS; do
  if [[ -e "$path" ]]; then
    chown -R "$TARGET_USER":"$TARGET_GROUP" "$path"
  fi
  done

if [[ -f "$REPO_ROOT/scripts/sync-halext-perms.sh" ]]; then
  "$REPO_ROOT/scripts/sync-halext-perms.sh" "$REPO_ROOT" "$TARGET_USER"
fi

echo "Setting default shell for $TARGET_USER to /bin/bash and ensuring home perms..."
usermod -s /bin/bash "$TARGET_USER"
chmod 700 "/home/$TARGET_USER"
if [[ -d "/home/$TARGET_USER/.ssh" ]]; then
  chmod 700 "/home/$TARGET_USER/.ssh"
  chmod 600 "/home/$TARGET_USER/.ssh"/* 2>/dev/null || true
fi

cat <<SUMMARY
Done. Review checklist:
  - Verify $TARGET_USER can read /var/log/nginx/error.log (requires newgrp or re-login).
  - Remove $LEGACY_USER from sudoers or delete the account once backups are confirmed.
  - Update any cron jobs or systemd services that referenced $LEGACY_USER.
SUMMARY
