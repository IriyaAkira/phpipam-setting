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

# ===== 終了処理 =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Execute the stop script" | tee -a "$LOG_FILE"
"$SCRIPT_DIR/stop.sh"

# ===== docker ボリューム、イメージ、コンテナの削除 =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Delete Docker volumes, images, and containers" | tee -a "$LOG_FILE"
cd "$BASE_DIR"
"$DOCKER_BIN" compose down -v --rmi all

# ===== 再スタート処理 =====
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
