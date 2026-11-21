#!/bin/sh
# Railway wrapper for ezBookkeeping: keeps all state on one volume,
# derives the public URL, and creates the first account on first boot.
set -eu

DATA_DIR="${EBK_DATA_DIR:-/ezbookkeeping/data}"
BIN=/ezbookkeeping/ezbookkeeping
APP_UID=1000
APP_GID=1000

mkdir -p "$DATA_DIR/storage"

# Server
export EBK_SERVER_HTTP_ADDR="${EBK_SERVER_HTTP_ADDR:-0.0.0.0}"
export EBK_SERVER_HTTP_PORT="${EBK_SERVER_HTTP_PORT:-${PORT:-8080}}"
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export EBK_SERVER_DOMAIN="${EBK_SERVER_DOMAIN:-$RAILWAY_PUBLIC_DOMAIN}"
  export EBK_SERVER_ROOT_URL="${EBK_SERVER_ROOT_URL:-https://$RAILWAY_PUBLIC_DOMAIN/}"
fi
export EBK_SERVER_LOG_REQUEST="${EBK_SERVER_LOG_REQUEST:-false}"

# Storage: SQLite database and uploaded files both live on the volume
export EBK_DATABASE_TYPE="${EBK_DATABASE_TYPE:-sqlite3}"
export EBK_DATABASE_DB_PATH="${EBK_DATABASE_DB_PATH:-$DATA_DIR/ezbookkeeping.db}"
export EBK_STORAGE_TYPE="${EBK_STORAGE_TYPE:-local_filesystem}"
export EBK_STORAGE_LOCAL_FILESYSTEM_PATH="${EBK_STORAGE_LOCAL_FILESYSTEM_PATH:-$DATA_DIR/storage/}"
export EBK_LOG_MODE="${EBK_LOG_MODE:-console}"

# Security: public sign-up is off unless the deployer turns it on
export EBK_USER_ENABLE_REGISTER="${EBK_USER_ENABLE_REGISTER:-false}"
if [ -z "${EBK_SECURITY_SECRET_KEY:-}" ]; then
  # Fallback for deploys without the template variable: keep one key on the volume
  if [ ! -s "$DATA_DIR/.secret_key" ]; then
    head -c 48 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$DATA_DIR/.secret_key"
    chmod 600 "$DATA_DIR/.secret_key"
  fi
  EBK_SECURITY_SECRET_KEY="$(cat "$DATA_DIR/.secret_key")"
  export EBK_SECURITY_SECRET_KEY
fi

# Run as the image's non-root user (uid 1000). Railway volumes mount as root,
# so when started as root, fix ownership first and drop privileges with busybox su.
if [ "$(id -u)" = "0" ]; then
  chown -R "$APP_UID:$APP_GID" "$DATA_DIR"
  run() { su -p -s /bin/sh -c 'exec "$0" "$@"' -- ezbookkeeping "$@"; }
else
  run() { "$@"; }
fi

cd /ezbookkeeping

# Create or update the database tables before the first account is added
run "$BIN" database update >/dev/null

# First account, created once from ADMIN_* variables
if [ -n "${ADMIN_USERNAME:-}" ] && [ -n "${ADMIN_PASSWORD:-}" ] && [ ! -f "$DATA_DIR/.admin_created" ]; then
  if run "$BIN" userdata user-get --username "$ADMIN_USERNAME" >/dev/null 2>&1; then
    echo "railway-start: account '$ADMIN_USERNAME' already exists, not creating it"
  elif [ -z "${ADMIN_EMAIL:-}" ]; then
    echo "railway-start: ADMIN_EMAIL is empty, skipping first account creation" >&2
  else
    # user-add prints the password hash, so its output is discarded
    if run "$BIN" userdata user-add \
        --username "$ADMIN_USERNAME" \
        --email "$ADMIN_EMAIL" \
        --nickname "${ADMIN_NICKNAME:-$ADMIN_USERNAME}" \
        --password "$ADMIN_PASSWORD" \
        --default-currency "${ADMIN_DEFAULT_CURRENCY:-USD}" >/dev/null 2>&1; then
      echo "railway-start: created account '$ADMIN_USERNAME'"
    else
      echo "railway-start: could not create account '$ADMIN_USERNAME' (check ADMIN_* values)" >&2
      exit 1
    fi
  fi
  touch "$DATA_DIR/.admin_created"
  [ "$(id -u)" != "0" ] || chown "$APP_UID:$APP_GID" "$DATA_DIR/.admin_created"
fi

if [ "$(id -u)" = "0" ]; then
  exec su -p -s /bin/sh -c 'exec "$0" "$@"' -- ezbookkeeping "$BIN" server run
fi
exec "$BIN" server run
