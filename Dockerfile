# --- Stage 1: Build OpenClaw ---
FROM node:20-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y python3 make g++ git curl && \
    corepack enable && corepack prepare pnpm@latest --activate && \
    curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts
RUN pnpm install --frozen-lockfile

COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
RUN OPENCLAW_PREFER_PNPM=1 pnpm ui:build
RUN pnpm prune --production

# --- Stage 2: Final Runtime (Lean & Functional) ---
FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=production \
    OLLAMA_HOST=0.0.0.0

RUN apt-get update && apt-get install -y \
    curl ca-certificates tini procps sudo \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && curl -fsSL https://ollama.com/install.sh | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create 'dev' user and prepare the workspace in his home directory
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# --- Set Workspace to /home/dev/openclaw ---
WORKDIR /home/dev/openclaw

# Copy built app from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY entrypoint.sh /entrypoint.sh

# Create the standard OpenClaw data folders in the home dir
RUN mkdir -p /home/dev/.openclaw /home/dev/openclaw/workspace /home/dev/.ollama && \
    chmod +x /entrypoint.sh && \
    chown -R dev:dev /home/dev

# Persist configuration and workspace
VOLUME ["/home/dev/.openclaw", "/home/dev/openclaw/workspace", "/home/dev/.ollama"]

USER dev
EXPOSE 11434 18789
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
