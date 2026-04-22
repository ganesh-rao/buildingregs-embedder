#!/usr/bin/env python3

from __future__ import annotations

import argparse
import base64
import json
import sys
from pathlib import Path
from urllib import request

sys.dont_write_bytecode = True


def parse_embedding(body: object) -> list[float]:
    if isinstance(body, list):
        body = body[0]

    if not isinstance(body, dict):
        raise SystemExit(f"Unexpected response type: {type(body)!r}")

    embedding = body["embedding"]
    if embedding and isinstance(embedding[0], list):
        embedding = embedding[0]

    return embedding


def embed_text(base_url: str, text: str) -> list[float]:
    payload = {"content": text}
    req = request.Request(
        base_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    with request.urlopen(req, timeout=1800) as response:
        body = json.loads(response.read().decode("utf-8"))
    return parse_embedding(body)


def embed_image(base_url: str, image_path: Path) -> list[float]:
    image_b64 = base64.b64encode(image_path.read_bytes()).decode("ascii")
    payload = {
        "content": [
            {
                "prompt_string": "<__media__>\n",
                "multimodal_data": [image_b64],
            }
        ]
    }
    req = request.Request(
        base_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    with request.urlopen(req, timeout=1800) as response:
        body = json.loads(response.read().decode("utf-8"))
    return parse_embedding(body)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Send a text or image embedding request to the local llama-server bundle."
    )
    parser.add_argument(
        "--base-url",
        default="http://127.0.0.1:8095/embeddings",
        help="llama-server embeddings endpoint.",
    )
    parser.add_argument(
        "--text",
        help="Text content to embed, for example 'Query: ...' or 'Passage: ...'.",
    )
    parser.add_argument(
        "--image",
        type=Path,
        help="Optional local image path to embed.",
    )
    args = parser.parse_args()

    if bool(args.text) == bool(args.image):
        raise SystemExit("Provide exactly one of --text or --image.")

    if args.image is not None:
        if not args.image.is_file():
            raise SystemExit(f"Image not found: {args.image}")
        embedding = embed_image(args.base_url, args.image)
    else:
        embedding = embed_text(args.base_url, args.text)

    print("embedding_length:", len(embedding))
    print("embedding_first_8:", embedding[:8])


if __name__ == "__main__":
    main()
