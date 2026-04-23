#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
MODEL_DIR="${MODEL_DIR:-/models/nemotron-embed-vl-1b-v2}"

# Railpack-style container deploys need the server bound on all interfaces.
export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-80}"
export MODEL_DIR
export MODEL_PATH="${MODEL_PATH:-${MODEL_DIR}/nvidia-llama-nemotron-embed-vl-1b-v2-bf16.gguf}"
export MMPROJ_PATH="${MMPROJ_PATH:-${MODEL_DIR}/nvidia-llama-nemotron-embed-vl-1b-v2-mmproj-bf16.gguf}"
export PYTHONPATH="${SCRIPT_DIR}/.python-packages${PYTHONPATH:+:${PYTHONPATH}}"

python3 "${SCRIPT_DIR}/download_models.py"

exec "${SCRIPT_DIR}/serve.sh"
