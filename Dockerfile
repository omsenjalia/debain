# 1. Base Image
FROM node:22-bookworm-slim

# 2. CPU-Specific Environment Setup
ENV DEBIAN_FRONTEND=noninteractive \
    OLLAMA_HOST=0.0.0.0 \
    OLLAMA_MODELS="/home/dev/.ollama" \
    # Force Ollama to ignore any partial GPU signatures and use CPU
    CUDA_VISIBLE_DEVICES="-1" \
    # Optimize for multiple CPU cores (adjust based on your machine)
    OLLAMA_NUM_PARALLEL=4 \
    # Fix for PNPM Global Binaries
    PNPM_HOME="/usr/local/share/pnpm" \
    PATH="/usr/local/share/pnpm:${PATH}"

# 3. Install Essentials (No GPU tools needed)
RUN apt-get update && apt-get install -y \
    curl ca-certificates tini procps sudo zstd git \
    && curl -fsSL https://ollama.com/install.sh | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. Setup User
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 5. Install pnpm and OpenClaw
RUN npm install -g pnpm && \
    pnpm config set global-bin-dir /usr/local/bin && \
    pnpm add -g openclaw

# 6. Bake the Models (Warning: Massive downloads ahead)
RUN ollama serve & sleep 20 && \
    ollama pull gpt-oss:120b-cloud && \
    ollama pull kimi-k2.5:cloud && \
    ollama pull gpt-oss:20b-cloud && \
    ollama pull deepseek-v3.1:671b-cloud && \
    ollama pull glm-4.7:cloud && \
    pkill ollama

# 7. Final Setup - Fixed Permissions
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    # Create directories first
    mkdir -p /home/dev/.openclaw /home/dev/workspace /tmp/ollama-backups && \
    # Give 'dev' ownership of the entire home directory and the backup temp folder
    chown -R dev:dev /home/dev /tmp/ollama-backups && \
    # Ensure read/write/execute permissions for the owner
    chmod -R 755 /home/dev /tmp/ollama-backups

EXPOSE 11434 18789
USER dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
