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
echo "$(date '+%Y-%m-%d %H:%M:%S'): Execute the stop script" | tee -a "${LOG_FILE}"
if bash "${SCRIPT_DIR}/stop.sh"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Stop script completed successfully." | tee -a "${LOG_FILE}"
else
    echo "ERROR: Stop script failed." | tee -a "${LOG_FILE}"
    exit 1
fi

# ===== 再スタート処理 =====
echo "$(date '+%Y-%m-%d %H:%M:%S'): Execute the start script" | tee -a "${LOG_FILE}"
if bash "${SCRIPT_DIR}/start.sh"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Start script completed successfully." | tee -a "${LOG_FILE}"
else
    echo "ERROR: Start script failed." | tee -a "${LOG_FILE}"
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
