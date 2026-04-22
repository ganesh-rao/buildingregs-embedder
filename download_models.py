from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import hashlib
import os
import sys

import boto3
from boto3.s3.transfer import TransferConfig
from botocore.config import Config


@dataclass(frozen=True)
class ModelArtifact:
  filename: str
  key: str
  sha256: str
  size_bytes: int


ARTIFACTS = [
  ModelArtifact(
    filename="nvidia-llama-nemotron-embed-vl-1b-v2-bf16.gguf",
    key="rag/models/nemotron-embed-vl-1b-v2/nvidia-llama-nemotron-embed-vl-1b-v2-bf16.gguf",
    sha256="36483a007a6137094d948b71f7306f7e835de4582838e0e7325b531d076967be",
    size_bytes=2479637152,
  ),
  ModelArtifact(
    filename="nvidia-llama-nemotron-embed-vl-1b-v2-mmproj-bf16.gguf",
    key="rag/models/nemotron-embed-vl-1b-v2/nvidia-llama-nemotron-embed-vl-1b-v2-mmproj-bf16.gguf",
    sha256="1945061233f3a75d394bd4c60b57e2ec5169ed94d341c7d23ed1d14f2fb2cc44",
    size_bytes=859339232,
  ),
]


def required_env(name: str) -> str:
  value = os.environ.get(name, "").strip()
  if not value:
    raise RuntimeError(f"{name} is required to download embedder models")
  return value


def sha256_file(path: Path) -> str:
  digest = hashlib.sha256()
  with path.open("rb") as handle:
    for block in iter(lambda: handle.read(16 * 1024 * 1024), b""):
      digest.update(block)
  return digest.hexdigest()


def artifact_ok(path: Path, artifact: ModelArtifact) -> bool:
  if not path.exists():
    return False
  if path.stat().st_size != artifact.size_bytes:
    return False
  return sha256_file(path) == artifact.sha256


def build_client():
  return boto3.client(
    "s3",
    endpoint_url=required_env("RAG_AWS_ENDPOINT_URL"),
    region_name=os.environ.get("RAG_AWS_REGION", "auto"),
    aws_access_key_id=required_env("RAG_AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=required_env("RAG_AWS_SECRET_ACCESS_KEY"),
    config=Config(signature_version="s3v4"),
  )


def download_artifact(client, bucket: str, model_dir: Path, artifact: ModelArtifact) -> None:
  destination = model_dir / artifact.filename
  if artifact_ok(destination, artifact):
    print(f"model_present path={destination} size={artifact.size_bytes} sha256={artifact.sha256}", flush=True)
    return

  temporary = destination.with_suffix(destination.suffix + ".part")
  if temporary.exists():
    temporary.unlink()

  print(f"model_download_start key={artifact.key} path={destination}", flush=True)
  client.download_file(
    bucket,
    artifact.key,
    str(temporary),
    Config=TransferConfig(
      multipart_threshold=64 * 1024 * 1024,
      multipart_chunksize=64 * 1024 * 1024,
      max_concurrency=int(os.environ.get("MODEL_DOWNLOAD_CONCURRENCY", "4")),
      use_threads=True,
    ),
  )
  temporary.replace(destination)

  if not artifact_ok(destination, artifact):
    raise RuntimeError(
      f"downloaded model verification failed for {destination}; "
      f"expected size={artifact.size_bytes} sha256={artifact.sha256}"
    )
  print(f"model_download_complete path={destination} size={artifact.size_bytes} sha256={artifact.sha256}", flush=True)


def main() -> int:
  model_dir = Path(os.environ.get("MODEL_DIR", "/models/nemotron-embed-vl-1b-v2")).resolve()
  model_dir.mkdir(parents=True, exist_ok=True)
  bucket = required_env("RAG_S3_BUCKET")
  client = build_client()

  for artifact in ARTIFACTS:
    download_artifact(client, bucket, model_dir, artifact)

  print(f"models_ready dir={model_dir}", flush=True)
  return 0


if __name__ == "__main__":
  try:
    raise SystemExit(main())
  except Exception as exc:
    print(f"model_download_failed: {exc}", file=sys.stderr, flush=True)
    raise SystemExit(1) from exc
