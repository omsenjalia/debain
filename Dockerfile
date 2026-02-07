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
# Entrypoint script
# --------------------
RUN echo '#!/usr/bin/env bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo 'echo "Starting Ollama on default port 11434..."' >> /entrypoint.sh && \
    echo 'ollama serve &' >> /entrypoint.sh && \
    echo 'sleep 2' >> /entrypoint.sh && \
    echo 'echo "Ollama running."' >> /entrypoint.sh && \
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
