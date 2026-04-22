#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RUN_DIR="${LLAMA_RUN_DIR:-${XDG_RUNTIME_DIR:-/tmp}/gguff-llama-nemotron-embed-vl-1b-v2}"
PID_FILE="${RUN_DIR}/llama-server.pid"
LOG_FILE="${RUN_DIR}/llama-server.log"

mkdir -p "${RUN_DIR}"

if [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null; then
  echo "llama-server is already running with pid $(cat "${PID_FILE}")"
  exit 1
fi

rm -f "${PID_FILE}"

setsid "${SCRIPT_DIR}/serve.sh" >"${LOG_FILE}" 2>&1 < /dev/null &
echo $! >"${PID_FILE}"

sleep 1

if ! kill -0 "$(cat "${PID_FILE}")" 2>/dev/null; then
  echo "llama-server exited during startup"
  echo "log: ${LOG_FILE}"
  rm -f "${PID_FILE}"
  exit 1
fi

echo "started pid $(cat "${PID_FILE}")"
echo "log: ${LOG_FILE}"
