# --- STAGE 1: Grab OpenClaw binary ---
FROM ghcr.io/openclaw/openclaw:latest AS openclaw_base

# --- STAGE 2: Build our actual image ---
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    OLLAMA_HOST=0.0.0.0

# 1. Install System Essentials & Ollama
RUN apt-get update && apt-get install -y \
    curl ca-certificates tini procps sudo \
    && curl -fsSL https://ollama.com/install.sh | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Setup user
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Copy OpenClaw from the first stage
# This brings the app into our Debian environment
COPY --from=openclaw_base /usr/local/bin/openclaw /usr/local/bin/openclaw
COPY --from=openclaw_base /app /home/dev/openclaw/app

WORKDIR /home/dev/openclaw

# 4. Copy your entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 5. Final Setup
RUN mkdir -p /home/dev/.openclaw /home/dev/openclaw/workspace /home/dev/.ollama && \
    chown -R dev:dev /home/dev

EXPOSE 11434 18789

USER dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
