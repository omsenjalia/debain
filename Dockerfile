# --- STAGE 1: Grab OpenClaw & Clean it ---
FROM ghcr.io/openclaw/openclaw:latest AS openclaw_base

FROM node:22-slim AS cleaner
# Set the workdir
WORKDIR /app

# Instead of assuming /app, let's copy whatever was the WORKDIR in the base image
# Most official Node images use /app, but let's be explicit.
COPY --from=openclaw_base /app ./

# Check if package.json exists before pruning to avoid Exit Code 1
RUN if [ -f package.json ]; then \
      npm prune --omit=dev && \
      rm -rf test tests docs .git .github coverage node_modules/.cache src; \
    else \
      echo "Warning: package.json not found in /app, skipping prune"; \
    fi
# --- STAGE 2: The Final Image with Models ---
FROM node:22-slim

ENV DEBIAN_FRONTEND=noninteractive \
    OLLAMA_HOST=0.0.0.0 \
    OLLAMA_MODELS="/home/dev/.ollama" \
    PATH="/home/dev/openclaw/app/node_modules/.bin:${PATH}"

# 1. Install Essentials & Ollama
RUN apt-get update && apt-get install -y \
    curl ca-certificates tini procps sudo zstd \
    && curl -fsSL https://ollama.com/install.sh | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Setup user
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Copy Cleaned App
WORKDIR /home/dev/openclaw
COPY --from=cleaner /app ./app
RUN ln -s /home/dev/openclaw/app/node_modules/.bin/openclaw /usr/local/bin/openclaw

# 4. BAKING THE MODELS (The "I Insist" Step)
# We must start the server, wait, pull everything, then shut it down cleanly
RUN ollama serve & sleep 10 && \
    echo "📥 Pulling 120b Primary..." && ollama pull gpt-oss:120b-cloud && \
    echo "📥 Pulling Kimi..." && ollama pull kimi-k2.5:cloud && \
    echo "📥 Pulling 20b..." && ollama pull gpt-oss:20b-cloud && \
    echo "📥 Pulling DeepSeek 671b..." && ollama pull deepseek-v3.1:671b-cloud && \
    echo "📥 Pulling GLM..." && ollama pull glm-4.7:cloud && \
    pkill ollama

# 5. Final Permissions
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /home/dev/.openclaw /home/dev/openclaw/workspace && \
    chown -R dev:dev /home/dev

EXPOSE 11434 18789
USER dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
