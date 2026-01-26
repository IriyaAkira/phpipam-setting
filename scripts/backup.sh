#!/bin/bash
set -eu

# ===== root チェック =====
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: docker_project_backup.sh must be run as root."
  exit 1
fi
echo "docker_project_backup.sh running as root"

# ===== 固定パス定義 =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_BIN="/usr/bin/docker"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
LOG_FILE="$SCRIPT_DIR/logs/${SCRIPT_NAME%.*}.log"

# ===== ログ開始 =====
echo "==== $(date '+%Y-%m-%d %H:%M:%S') START: ${SCRIPT_NAME} ====" | tee -a "$LOG_FILE"

# ===== .env読み込み =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Load env file" | tee -a "$LOG_FILE"
ENV_FILE="$BASE_DIR/.env"
set -a
. "$ENV_FILE"
set +a

# ===== DBバックアップ =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting to create a db dump." | tee -a "$LOG_FILE"
BACKUP_FILE="$BASE_DIR/db_init/db_dump.sql"

cd "$BASE_DIR"
"$DOCKER_BIN" compose exec -T phpipam-mariadb \
  mariadb-dump \
    -u"$MYSQL_ROOT_USERNAME" \
    -p"$MYSQL_ROOT_PASSWORD" \
    --all-databases \
  > "$BACKUP_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S'): Complete creating a db dump."

# ===== プロジェクトバックアップ =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting project backup." | tee -a "$LOG_FILE"
# docker停止
echo "$(date '+%Y-%m-%d %H:%M:%S'): Stop phpipam server..." | tee -a "$LOG_FILE"
cd "$BASE_DIR"
"$DOCKER_BIN" compose down

# .smbcredentialsファイルの存在チェック
echo "$(date '+%Y-%m-%d %H:%M:%S'): Check for the existence of the .smbcredentials file" | tee -a "$LOG_FILE"
CRED_FILE="/root/.smbcredentials"
if [ ! -f "$CRED_FILE" ]; then
    echo "ERROR: A backup of the project cannot be created because the relevant file is not found."
    echo "file: ${CRED_FILE}"
    exit 1
fi

# バックアップ先のマウント
echo "$(date '+%Y-%m-%d %H:%M:%S'): Mount file server." | tee -a "$LOG_FILE"
MOUNT_POINT="/mnt/docker_backup"
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
fi

if ! mountpoint -q "$MOUNT_POINT"; then
    mount -t cifs "//${BK_SERVER}/${BK_SHARE}" "$MOUNT_POINT" \
        -o credentials="$CRED_FILE",iocharset=utf8,vers=3.0 \
        2>&1 | tee -a "$LOG_FILE"
fi

# バックアップ
echo "$(date '+%Y-%m-%d %H:%M:%S'): Execute backup" | tee -a "$LOG_FILE"
SRC_DIR="${BASE_DIR}/"
DST_DIR="${MOUNT_POINT}/docker/glpi/"
rsync -av --delete --exclude='*/.git/'\
    "$SRC_DIR" \
    "$DST_DIR" \
    2>&1 | tee -a "$LOG_FILE"

# バックアップ先のアンマウント
echo "$(date '+%Y-%m-%d %H:%M:%S'): Unmount file server." | tee -a "$LOG_FILE"
umount "$MOUNT_POINT"

# 再スタート処理
echo "$(date '+%Y-%m-%d %H:%M:%S'): Execute the start script" | tee -a "$LOG_FILE"
"$SCRIPT_DIR/start.sh"

# ===== ログファイルの容量制限 =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Start log file size limit" | tee -a "$LOG_FILE"
MAX_LINES=10000
if [[ -f "$LOG_FILE" ]]; then
  tail -n "$MAX_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp"
  mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi
echo "$(date '+%Y-%m-%d %H:%M:%S'): Complete log file size limit" | tee -a "$LOG_FILE"

# ===== ログ終了 =====
echo "==== $(date '+%Y-%m-%d %H:%M:%S') END: ${SCRIPT_NAME} ====" | tee -a "$LOG_FILE"
