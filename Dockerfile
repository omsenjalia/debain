FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# --------------------
# Base packages (ADD zstd)
# --------------------
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    sudo \
    bash \
    git \
    procps \
    tini \
    zstd \
    && rm -rf /var/lib/apt/lists/*

# --------------------
# Node.js
# --------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# --------------------
# Ollama (now works)
# --------------------
RUN curl -fsSL https://ollama.com/install.sh | bash

# --------------------
# User with sudo
# --------------------
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /workspace
RUN mkdir -p /home/dev/.ollama && chown -R dev:dev /home/dev

# --------------------
# OpenClaw (install only, no config / no auto-start)
# --------------------
# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# Allow non-root user to write temp files during runtime/tests.
RUN chown -R node:node /app

# Security hardening: Run as non-root user
# The node:22-bookworm image includes a 'node' user (uid 1000)
# This reduces the attack surface by preventing container escape via root privileges

# --------------------
# Entrypoint script
# --------------------
RUN echo '#!/usr/bin/env bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo 'echo "Starting Ollama on default port 11434..."' >> /entrypoint.sh && \
    echo 'ollama serve &' >> /entrypoint.sh && \
    echo 'sleep 2' >> /entrypoint.sh && \
    echo 'echo "Ollama running."' >> /entrypoint.sh && \
    echo 'ollama launch openclaw --model gpt-oss:120b-cloud &' >> /entrypoint.sh && \
    echo 'sleep 2' >> /entrypoint.sh && \
    echo 'echo "openclaw running."' >> /entrypoint.sh && \
    echo 'exec bash' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# --------------------
# Ports
# --------------------
EXPOSE 11434
EXPOSE 18789

USER dev

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
