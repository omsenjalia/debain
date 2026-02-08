# --- STAGE 1: Grab OpenClaw & Clean it ---
FROM ghcr.io/openclaw/openclaw:latest AS openclaw_base

# Intermediate "Cleaner" stage
# We use Node 22 to match the target runtime
FROM node:22-slim AS cleaner
WORKDIR /app

# Copy the app from the source image
COPY --from=openclaw_base /app .

# ✂️ THE CLEANUP:
# 1. Prune dev dependencies (removes compilers, test suites)
# 2. Delete heavy source folders that aren't needed for running the bot
RUN npm prune --production && \
    rm -rf test tests docs .git .github coverage node_modules/.cache src

# --- STAGE 2: The Final Slim Image ---
FROM node:22-slim

ENV DEBIAN_FRONTEND=noninteractive \
    OLLAMA_HOST=0.0.0.0 \
    # Add the local binary path so 'openclaw' command works anywhere
    PATH="/home/dev/openclaw/app/node_modules/.bin:${PATH}"

# 1. Install System Essentials & Ollama
# We don't need to install Node or NPM - they are already here!
RUN apt-get update && apt-get install -y \
    curl ca-certificates tini procps sudo zstd \
    && curl -fsSL https://ollama.com/install.sh | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Setup user
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Copy ONLY the cleaned app from the cleaner stage
WORKDIR /home/dev/openclaw
COPY --from=cleaner /app ./app

# 4. Create the global symlink manually to be 100% safe
RUN ln -s /home/dev/openclaw/app/node_modules/.bin/openclaw /usr/local/bin/openclaw

# 5. Final Setup
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /home/dev/.openclaw /home/dev/openclaw/workspace /home/dev/.ollama && \
    chown -R dev:dev /home/dev

EXPOSE 11434 18789

USER dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
