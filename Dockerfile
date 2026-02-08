# --- STAGE 1: Build Stage (The heavy lifting) ---
FROM node:20-slim AS builder
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y python3 make g++ git curl && \
    corepack enable && corepack prepare pnpm@latest --activate && \
    curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Copy only the configuration files you HAVE to optimize caching
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json

# Install dependencies (only what's in the lockfile)
RUN pnpm install --frozen-lockfile

# Copy the rest of the source code (this is safe even without scripts/ folder)
COPY . .

# Run the OpenClaw build commands for 2026
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
RUN OPENCLAW_PREFER_PNPM=1 pnpm ui:build

# Remove development-only libraries to shrink the folder
RUN pnpm prune --production


# --- STAGE 2: Runtime Stage (The lean production image) ---
FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=production \
    OLLAMA_HOST=0.0.0.0

# Install ONLY runtime essentials: Node.js, Ollama, and tiny utilities
RUN apt-get update && apt-get install -y \
    curl ca-certificates tini procps sudo \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && curl -fsSL https://ollama.com/install.sh | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create our 'dev' user for safety
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Move to the home directory as requested
WORKDIR /home/dev/openclaw

# Copy ONLY the compiled app and modules from the builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
# Make sure your entrypoint.sh is in the root of your repo
COPY entrypoint.sh /entrypoint.sh

# Setup permissions and create standard workspace folders
RUN mkdir -p /home/dev/.openclaw /home/dev/openclaw/workspace /home/dev/.ollama && \
    chmod +x /entrypoint.sh && \
    chown -R dev:dev /home/dev

# Expose Ollama (11434) and OpenClaw (18789)
EXPOSE 11434 18789

USER dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
