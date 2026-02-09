# 1. Base Image: Best balance of size and compatibility
FROM node:22-bookworm-slim

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive \
    OLLAMA_HOST=0.0.0.0 \
    OLLAMA_MODELS="/home/dev/.ollama"

# 2. Install Essentials + GIT (Critical for pnpm/npm git dependencies)
RUN apt-get update && apt-get install -y \
    curl ca-certificates tini procps sudo zstd git \
    && curl -fsSL https://ollama.com/install.sh | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Setup User 'dev'
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 4. Install pnpm and OpenClaw
# We install pnpm globally first, then use it to install openclaw
RUN npm install -g pnpm && pnpm add -g openclaw

# 5. Bake the Models (The Big Step)
# We start Ollama, wait for it to be ready, pull models, then kill it.
# Note: This will increase image size by hundreds of GBs.
RUN ollama serve & sleep 20 && \
    echo "🔴 Pulling gpt-oss:120b-cloud..." && ollama pull gpt-oss:120b-cloud && \
    echo "🔴 Pulling kimi-k2.5:cloud..." && ollama pull kimi-k2.5:cloud && \
    echo "🔴 Pulling gpt-oss:20b-cloud..." && ollama pull gpt-oss:20b-cloud && \
    echo "🔴 Pulling deepseek-v3.1:671b-cloud..." && ollama pull deepseek-v3.1:671b-cloud && \
    echo "🔴 Pulling glm-4.7:cloud..." && ollama pull glm-4.7:cloud && \
    pkill ollama

# 6. Final Setup
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /home/dev/.openclaw /home/dev/workspace && \
    chown -R dev:dev /home/dev

EXPOSE 11434 18789
USER dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
