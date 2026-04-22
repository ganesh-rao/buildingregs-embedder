#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RUN_DIR="${LLAMA_RUN_DIR:-${XDG_RUNTIME_DIR:-/tmp}/gguff-llama-nemotron-embed-vl-1b-v2}"
PID_FILE="${RUN_DIR}/llama-server.pid"

if [[ ! -f "${PID_FILE}" ]]; then
  echo "no pid file at ${PID_FILE}"
  exit 0
fi

PID=$(cat "${PID_FILE}")

if kill -0 "${PID}" 2>/dev/null; then
  kill "${PID}"
  wait "${PID}" 2>/dev/null || true
  echo "stopped pid ${PID}"
else
  echo "process ${PID} is not running"
fi

rm -f "${PID_FILE}"
