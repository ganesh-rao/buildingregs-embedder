#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
COMPAT_DIR="${SCRIPT_DIR}/compat/glibc-2.39"
COMPAT_LIB_DIR="${COMPAT_DIR}/lib/x86_64-linux-gnu"
COMPAT_LOADER="${COMPAT_DIR}/lib64/ld-linux-x86-64.so.2"
BASE_LIBRARY_PATH="${SCRIPT_DIR}/lib"

if [[ -d "${COMPAT_LIB_DIR}" ]]; then
  BASE_LIBRARY_PATH="${BASE_LIBRARY_PATH}:${COMPAT_LIB_DIR}"
fi

export LD_LIBRARY_PATH="${BASE_LIBRARY_PATH}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

MODEL_PATH="${MODEL_PATH:-${SCRIPT_DIR}/models/nvidia-llama-nemotron-embed-vl-1b-v2-bf16.gguf}"
MMPROJ_PATH="${MMPROJ_PATH:-${SCRIPT_DIR}/models/nvidia-llama-nemotron-embed-vl-1b-v2-mmproj-bf16.gguf}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8095}"
CTX_SIZE="${CTX_SIZE:-4096}"
BATCH_SIZE="${BATCH_SIZE:-4096}"
UBATCH_SIZE="${UBATCH_SIZE:-4096}"
IMAGE_MAX_TOKENS="${IMAGE_MAX_TOKENS:-1024}"
PARALLEL="${PARALLEL:-1}"
LLAMA_SERVER_EXTRA_ARGS="${LLAMA_SERVER_EXTRA_ARGS:-}"

if [[ ! -x "${SCRIPT_DIR}/bin/llama-server" ]]; then
  echo "llama-server binary not found or not executable: ${SCRIPT_DIR}/bin/llama-server" >&2
  exit 1
fi

if [[ ! -f "${MODEL_PATH}" ]]; then
  echo "model not found: ${MODEL_PATH}" >&2
  exit 1
fi

if [[ ! -f "${MMPROJ_PATH}" ]]; then
  echo "mmproj not found: ${MMPROJ_PATH}" >&2
  exit 1
fi

if [[ -x "${COMPAT_LOADER}" ]]; then
  exec "${COMPAT_LOADER}" \
    --library-path "${LD_LIBRARY_PATH}" \
    "${SCRIPT_DIR}/bin/llama-server" \
    -m "${MODEL_PATH}" \
    --mmproj "${MMPROJ_PATH}" \
    --embedding \
    --pooling mean \
    --ctx-size "${CTX_SIZE}" \
    --batch-size "${BATCH_SIZE}" \
    --ubatch-size "${UBATCH_SIZE}" \
    --image-max-tokens "${IMAGE_MAX_TOKENS}" \
    -np "${PARALLEL}" \
    --host "${HOST}" \
    --port "${PORT}" \
    ${LLAMA_SERVER_EXTRA_ARGS}
fi

exec "${SCRIPT_DIR}/bin/llama-server" \
  -m "${MODEL_PATH}" \
  --mmproj "${MMPROJ_PATH}" \
  --embedding \
  --pooling mean \
  --ctx-size "${CTX_SIZE}" \
  --batch-size "${BATCH_SIZE}" \
  --ubatch-size "${UBATCH_SIZE}" \
  --image-max-tokens "${IMAGE_MAX_TOKENS}" \
  -np "${PARALLEL}" \
  --host "${HOST}" \
  --port "${PORT}" \
  ${LLAMA_SERVER_EXTRA_ARGS}
