#!/bin/bash
set -eu

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$BASE_DIR/.env"
BACKUP_FILE="$BASE_DIR/db_init/db_cron_dump.sql"
DOCKER_BIN="/usr/bin/docker"
LOG_FILE="$BASE_DIR/scripts/logs/db_backup.log"

### ログ開始 ###
echo "==== $(date '+%Y-%m-%d %H:%M:%S') START ====" >> "$LOG_FILE"

### dbバックアップ ###
echo "$(date '+%Y-%m-%d %H:%M:%S'): dbのdump作成開始" >> "$LOG_FILE"
cd "$BASE_DIR"

set -a
. "$ENV_FILE"
set +a

"$DOCKER_BIN" compose exec -T phpipam-mariadb \
  mariadb-dump \
    -u"$MYSQL_ROOT_USERNAME" \
    -p"$MYSQL_ROOT_PASSWORD" \
    --all-databases \
  > "$BACKUP_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S'): dbのdump作成完了" >> "$LOG_FILE"

### ログファイルの容量制限 ###
echo "$(date '+%Y-%m-%d %H:%M:%S'): ログファイルの容量制限開始" >> "$LOG_FILE"
MAX_LINES=10000
if [[ -f "$LOG_FILE" ]]; then
  tail -n "$MAX_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp"
  mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi
echo "$(date '+%Y-%m-%d %H:%M:%S'): ログファイルの容量制限完了" >> "$LOG_FILE"

echo "==== $(date '+%Y-%m-%d %H:%M:%S') END ====" >> "$LOG_FILE"

