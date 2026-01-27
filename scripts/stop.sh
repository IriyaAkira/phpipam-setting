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

# ===== 終了処理 =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Changing directory to ${BASE_DIR}" | tee -a "${LOG_FILE}"
cd "${BASE_DIR}"
echo "$(date '+%Y-%m-%d %H:%M:%S'): Stop phpipam server..." | tee -a "${LOG_FILE}"
if "${DOCKER_BIN}" compose down 2>&1 | tee -a "${LOG_FILE}"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): phpipam server stopped successfully." | tee -a "${LOG_FILE}"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S'): WARNING: Failed to stop phpipam server or containers not found. Continuing..." | tee -a "${LOG_FILE}"
fi

# ===== 定期バックアップ用のcron解除 =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Disable cron..." | tee -a "${LOG_FILE}"
CRON_TAG="phpipam_backup"

## 既存 crontab 取得
CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

## 既存登録があれば削除
FILTERED_CRON="$(printf "%s\n" "${CURRENT_CRON}" | grep -v "${CRON_TAG}" || true)"

## crontab を更新
if printf "%s\n" "${FILTERED_CRON}" | crontab - 2>&1 | tee -a "${LOG_FILE}"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Cron job disabled successfully." | tee -a "${LOG_FILE}"
else
    echo "ERROR: Failed to disable cron job." | tee -a "${LOG_FILE}"
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
