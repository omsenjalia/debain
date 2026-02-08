# 1. Use the official OpenClaw production image as our base
# This already has the app installed, so we don't need package.json
FROM ghcr.io/openclaw/openclaw:latest

USER root

# 2. Install Ollama inside this image
RUN apt-get update && apt-get install -y curl procps tini sudo && \
    curl -fsSL https://ollama.com/install.sh | bash && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Setup your 'dev' user and workspace
RUN useradd -m -s /bin/bash dev || echo "User exists" && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 4. Copy your custom entrypoint into the image
WORKDIR /home/dev/openclaw
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 5. Create the folders for your 128k context and workspace
RUN mkdir -p /home/dev/.openclaw /home/dev/openclaw/workspace /home/dev/.ollama && \
    chown -R dev:dev /home/dev

# 6. Set the same ports
EXPOSE 11434 18789

USER dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
