# --- STAGE 1: Grab OpenClaw files ---
FROM ghcr.io/openclaw/openclaw:latest AS openclaw_base

# --- STAGE 2: Final Build ---
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    OLLAMA_HOST=0.0.0.0 \
    OLLAMA_MODELS="/home/dev/.ollama"

# 1. Install Essentials, Node.js, and Ollama
RUN apt-get update && apt-get install -y \
    curl ca-certificates tini procps sudo zstd \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && curl -fsSL https://ollama.com/install.sh | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Setup user
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Copy OpenClaw and create Symbolic Link
WORKDIR /home/dev/openclaw
COPY --from=openclaw_base /app ./app
RUN ln -s /home/dev/openclaw/app/node_modules/.bin/openclaw /usr/local/bin/openclaw

# 4. PRE-PULL MODELS (This is where the size explodes)
# We start the server, pull, then kill the server to finalize the layer
RUN ollama serve & sleep 5 && \
    ollama pull gpt-oss:120b-cloud && \
    ollama pull kimi-k2.5:cloud && \
    ollama pull gpt-oss:20b-cloud && \
    ollama pull deepseek-v3.1:671b-cloud && \
    ollama pull glm-4.7:cloud && \
    pkill ollama

# 5. Finalize setup
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /home/dev/.openclaw /home/dev/openclaw/workspace && \
    chown -R dev:dev /home/dev

EXPOSE 11434 18789
USER dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
