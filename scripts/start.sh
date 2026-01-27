#!/bin/bash
set -eu

# ===== 固定パス定義 =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKER_BIN="/usr/bin/docker"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
LOG_FILE="${SCRIPT_DIR}/logs/${SCRIPT_NAME%.*}.log"

# ===== root チェック =====
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: ${SCRIPT_NAME} must be run as root."
  exit 1
fi
echo "${SCRIPT_NAME} running as root"

# ===== ログ開始 =====
echo "==== $(date '+%Y-%m-%d %H:%M:%S') START: ${SCRIPT_NAME} ====" | tee -a "${LOG_FILE}"

# ===== 立ち上げ =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Changing directory to ${BASE_DIR}" | tee -a "${LOG_FILE}"
cd "${BASE_DIR}"
echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting phpipam server..." | tee -a "${LOG_FILE}"
if "${DOCKER_BIN}" compose up -d 2>&1 | tee -a "${LOG_FILE}"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): phpipam server started successfully." | tee -a "${LOG_FILE}"
else
    echo "ERROR: Failed to start phpipam server." | tee -a "${LOG_FILE}"
    exit 1
fi

# ===== 定期バックアップ用のcron設定 =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Setting cron..." | tee -a "${LOG_FILE}"
## cron 設定
BACKUP_SCRIPT="${SCRIPT_DIR}/backup.sh"
CRON_TAG="phpipam_backup"
CRON_LINE="0 3 * * * PATH=/usr/bin:/bin ${BACKUP_SCRIPT} # ${CRON_TAG}"

## 既存 crontab 取得
CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

## 既存登録があれば削除
FILTERED_CRON="$(printf "%s\n" "${CURRENT_CRON}" | grep -v "${CRON_TAG}" || true)"

## 新規登録
if printf "%s\n%s\n" "${FILTERED_CRON}" "${CRON_LINE}" | crontab - 2>&1 | tee -a "${LOG_FILE}"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Cron job registered successfully: ${CRON_LINE}" | tee -a "${LOG_FILE}"
else
    echo "ERROR: Failed to register cron job." | tee -a "${LOG_FILE}"
    exit 1
fi

# ===== ログファイルの容量制限 =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Start log file size limit" | tee -a "${LOG_FILE}"
MAX_LINES=10000
if [[ -f "${LOG_FILE}" ]]; then
  tail -n "${MAX_LINES}" "${LOG_FILE}" > "${LOG_FILE}.tmp"
  mv "${LOG_FILE}.tmp" "${LOG_FILE}"
fi
echo "$(date '+%Y-%m-%d %H:%M:%S'): Complete log file size limit" | tee -a "${LOG_FILE}"

# ===== ログ終了 =====
echo "==== $(date '+%Y-%m-%d %H:%M:%S') END: ${SCRIPT_NAME} ====" | tee -a "${LOG_FILE}"
