#!/bin/bash
set -eu

# ===== 固定パス定義 =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_BIN="/usr/bin/docker"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
LOG_FILE="$SCRIPT_DIR/logs/${SCRIPT_NAME%.*}.log"

# ===== ログ開始 =====
echo "==== $(date '+%Y-%m-%d %H:%M:%S') START: ${SCRIPT_NAME} ====" >> "$LOG_FILE"

# ===== 立ち上げ =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Changing directory to ${BASE_DIR}" >> "$LOG_FILE"
cd "$BASE_DIR"
echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting phpipam server..." >> "$LOG_FILE"
"$DOCKER_BIN" compose up -d

# ===== 定期バックアップ用のcron設定 =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Setting cron..." >> "$LOG_FILE"
## cron 設定
BACKUP_SCRIPT="$SCRIPT_DIR/backup.sh"
CRON_TAG="# phpipam backup"
CRON_LINE="0 3 * * * PATH=/usr/bin:/bin $BACKUP_SCRIPT $CRON_TAG"

## 既存 crontab 取得
CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

## 既存登録があれば削除
FILTERED_CRON="$(printf "%s\n" "$CURRENT_CRON" | grep -v "$CRON_TAG" || true)"

## 新規登録
printf "%s\n%s\n" "$FILTERED_CRON" "$CRON_LINE" | crontab -

echo "$(date '+%Y-%m-%d %H:%M:%S'): cron registered: $CRON_LINE" >> "$LOG_FILE"

# ===== ログファイルの容量制限 =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Start log file size limit" >> "$LOG_FILE"
MAX_LINES=10000
if [[ -f "$LOG_FILE" ]]; then
  tail -n "$MAX_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp"
  mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi
echo "$(date '+%Y-%m-%d %H:%M:%S'): Complete log file size limit" >> "$LOG_FILE"

# ===== ログ終了 =====
echo "==== $(date '+%Y-%m-%d %H:%M:%S') END: ${SCRIPT_NAME} ====" >> "$LOG_FILE"