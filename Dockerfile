FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    libgomp1 \
    libstdc++6 \
    python3 \
    python3-pip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

RUN python3 -m pip install --break-system-packages --no-cache-dir boto3 \
  && chmod +x /app/start.sh /app/serve.sh /app/bin/llama-server

ENV HOST=0.0.0.0
ENV PORT=80

CMD ["./start.sh"]
