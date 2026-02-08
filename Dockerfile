# --- STAGE 1: Grab OpenClaw files ---
FROM ghcr.io/openclaw/openclaw:latest AS openclaw_base

# --- STAGE 2: Build our actual image ---
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    OLLAMA_HOST=0.0.0.0 \
    PATH="/home/dev/openclaw/app/node_modules/.bin:${PATH}"

# 1. Install System Essentials, Zstd, Node.js (needed to run OpenClaw), & Ollama
RUN apt-get update && apt-get install -y \
    curl ca-certificates tini procps sudo zstd \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && curl -fsSL https://ollama.com/install.sh | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Setup user
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Copy the entire App folder from the official image
# We'll put it in /home/dev/openclaw/app
WORKDIR /home/dev/openclaw
COPY --from=openclaw_base /app ./app

# 4. Copy your entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 5. Final Setup for workspace and Ollama storage
RUN mkdir -p /home/dev/.openclaw /home/dev/openclaw/workspace /home/dev/.ollama && \
    chown -R dev:dev /home/dev

EXPOSE 11434 18789

USER dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
