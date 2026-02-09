# 1. Best efficient base
FROM node:22-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    OLLAMA_HOST=0.0.0.0 \
    OLLAMA_MODELS="/home/dev/.ollama"

# 2. Install System Essentials, OLLAMA, AND GIT
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    tini \
    procps \
    sudo \
    zstd \
    git \
    && curl -fsSL https://ollama.com/install.sh | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Setup User
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 4. Update NPM and Install OpenClaw globally
# Adding git support fixed the "enoent" error
RUN npm install -g npm@latest && npm i -g openclaw

# 5. Bake the Models (This part will take a while!)
RUN ollama serve & sleep 20 && \
    ollama pull gpt-oss:120b-cloud && \
    ollama pull kimi-k2.5:cloud && \
    ollama pull gpt-oss:20b-cloud && \
    ollama pull deepseek-v3.1:671b-cloud && \
    ollama pull glm-4.7:cloud && \
    pkill ollama

# 6. Final Config
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /home/dev/.openclaw /home/dev/workspace && \
    chown -R dev:dev /home/dev

EXPOSE 11434 18789
USER dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
