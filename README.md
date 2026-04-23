# gguff-llama-nemotron-embed-vl-1b-v2

This directory is a runtime-only `llama.cpp` bundle for serving the BF16 GGUF form of `nvidia-llama-nemotron-embed-vl-1b-v2`.

It contains only what is needed to serve embeddings locally:

- `bin/llama-server`
- the `lib/` shared libraries that binary needs
- the BF16 main GGUF
- the BF16 mmproj GGUF
- a small launcher and smoke test
- Dockerfile-based deployment files

It does not need the raw HF checkpoint, PyTorch, or vLLM at runtime.

## Included Files

- main GGUF: [models/nvidia-llama-nemotron-embed-vl-1b-v2-bf16.gguf](/home/ganesh-rao/dev/buildingregs/gguff-llama-nemotron-embed-vl-1b-v2/models/nvidia-llama-nemotron-embed-vl-1b-v2-bf16.gguf)
- mmproj GGUF: [models/nvidia-llama-nemotron-embed-vl-1b-v2-mmproj-bf16.gguf](/home/ganesh-rao/dev/buildingregs/gguff-llama-nemotron-embed-vl-1b-v2/models/nvidia-llama-nemotron-embed-vl-1b-v2-mmproj-bf16.gguf)
- server binary: [bin/llama-server](/home/ganesh-rao/dev/buildingregs/gguff-llama-nemotron-embed-vl-1b-v2/bin/llama-server)
- runtime libraries: [lib](/home/ganesh-rao/dev/buildingregs/gguff-llama-nemotron-embed-vl-1b-v2/lib)

## Quick Start

### Start in the foreground

```bash
cd /home/ganesh-rao/dev/buildingregs/gguff-llama-nemotron-embed-vl-1b-v2
./serve.sh
```

The default endpoints are:

- `http://127.0.0.1:8095/embeddings`
- `http://127.0.0.1:8095/v1/embeddings`

If you want it reachable from outside the host:

```bash
HOST=0.0.0.0 ./serve.sh
```

### Start in the background

```bash
cd /home/ganesh-rao/dev/buildingregs/gguff-llama-nemotron-embed-vl-1b-v2
./serve-background.sh
```

Logs go to:

- `${LLAMA_RUN_DIR:-${XDG_RUNTIME_DIR:-/tmp}/gguff-llama-nemotron-embed-vl-1b-v2}/llama-server.log`

Stop it with:

```bash
./stop.sh
```

## Deploy

This directory is deployment-friendly for Dockerfile-based hosts and DeployDash
Railpack:

- `Dockerfile` uses Ubuntu 24.04 so the bundled `llama-server` binary has
  compatible `glibc` and `libstdc++` versions.
- `railpack.json` also sets Railpack's final runtime base image to
  `ubuntu:24.04` for the same reason.
- `serve.sh` falls back to a bundled compatibility loader under
  `compat/glibc-2.39` because DeployDash's Railpack wrapper can still produce a
  Debian bookworm final image even when `railpack.json` requests Ubuntu 24.04.
- `railpack.json` installs Python and `boto3` for the startup model
  downloader.
- `start.sh` is the container entrypoint and binds `0.0.0.0`.
- `start.sh` uses `${PORT}` when the platform injects it and otherwise
  defaults to port `80`.
- GGUF files are downloaded from R2/S3 into `${MODEL_DIR}` at startup and
  verified by size and SHA-256 before `llama-server` starts.

Prefer Dockerfile mode where available. DeployDash currently uses Railpack for
this project, so `railpack.json` keeps that path compatible.

For a public temporary deployment, expose the container service publicly through
the hosting platform. The container serves HTTP; public HTTPS on port 443 should
be terminated by the platform edge/proxy. Do not attempt to make
`llama-server` manage TLS certificates directly.

Relevant runtime env vars:

- `PORT`
- `HOST`
- `MODEL_DIR` (default `/models/nemotron-embed-vl-1b-v2`; mount this as a
  persistent volume to avoid re-downloading on every deploy)
- `LLAMA_RUN_DIR`
- `MODEL_PATH`
- `MMPROJ_PATH`
- `CTX_SIZE`
- `BATCH_SIZE`
- `UBATCH_SIZE`
- `IMAGE_MAX_TOKENS`
- `CACHE_RAM` (default `0`, disables llama.cpp prompt cache to reduce memory)
- `NO_WARMUP` (default `1`, skips startup warmup to reduce peak memory)
- `PARALLEL`
- `LLAMA_SERVER_EXTRA_ARGS`
- `RAG_S3_BUCKET`
- `RAG_AWS_REGION`
- `RAG_AWS_ACCESS_KEY_ID`
- `RAG_AWS_SECRET_ACCESS_KEY`
- `RAG_AWS_ENDPOINT_URL`
- `MODEL_DOWNLOAD_CONCURRENCY`

R2 object keys:

- `rag/models/nemotron-embed-vl-1b-v2/nvidia-llama-nemotron-embed-vl-1b-v2-bf16.gguf`
- `rag/models/nemotron-embed-vl-1b-v2/nvidia-llama-nemotron-embed-vl-1b-v2-mmproj-bf16.gguf`

Expected hashes:

- main GGUF: `36483a007a6137094d948b71f7306f7e835de4582838e0e7325b531d076967be`
- mmproj GGUF: `1945061233f3a75d394bd4c60b57e2ec5169ed94d341c7d23ed1d14f2fb2cc44`

## Smoke Tests

Text query:

```bash
python3 smoke_test_embeddings.py \
  --text "Query: What is required for a cavity tray above an opening?"
```

Text passage:

```bash
python3 smoke_test_embeddings.py \
  --text "Passage: A cavity tray should be installed above an opening or lintel to divert moisture to weep holes."
```

Image:

```bash
python3 smoke_test_embeddings.py \
  --image /absolute/path/to/page.png
```

## Runtime Notes

- This bundle is CPU-only.
- The bundled GGUF pair is BF16, which is the highest-fidelity GGUF export currently available in this repo for this model.
- The serving path here is `llama.cpp`, not vLLM.
- `llama-server` returns the OpenAI-compatible endpoint at `/embeddings` and `/v1/embeddings`, but the exact JSON response shape may differ slightly from vLLM.

## Use With `rag`

This bundle can now be used as a first-class `rag` embedding backend.

```bash
export RAG_EMBEDDING_PROVIDER=openai
export OPENAI_BASE_URL=http://127.0.0.1:8095/v1
export OPENAI_EMBEDDING_MODEL=nvidia-llama-nemotron-embed-vl-1b-v2
export OPENAI_EMBEDDING_BATCH_SIZE=1
export OPENAI_IMAGE_EMBEDDING_BATCH_SIZE=1
```

## Environment Overrides

You can override these at launch time:

- `HOST`
- `PORT`
- `CTX_SIZE`
- `BATCH_SIZE`
- `UBATCH_SIZE`
- `IMAGE_MAX_TOKENS`
- `PARALLEL`
- `CACHE_RAM`
- `NO_WARMUP`

Example:

```bash
PORT=8097 ./serve.sh
```

For local runs, repo-local runtime files are no longer written by default:

- background PID and logs go to `${XDG_RUNTIME_DIR}` when available
- otherwise they go to `/tmp/gguff-llama-nemotron-embed-vl-1b-v2`
- the smoke test disables Python bytecode writes
