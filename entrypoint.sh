#!/usr/bin/env bash
set -e

# --- 1. ENVIRONMENT & PATHS ---
export OPENCLAW_STATE_DIR="/home/dev/.openclaw"
export OPENCLAW_WORKSPACE_DIR="/home/dev/openclaw/workspace"
export OLLAMA_MODELS="/home/dev/.ollama"

# Context optimization for the requested 128k limit
export OLLAMA_CONTEXT_LENGTH=131072
export OLLAMA_KEEP_ALIVE=24h

# --- 2. START OLLAMA SERVER ---
echo "🚀 Starting Ollama engine..."
ollama serve > /dev/null 2>&1 &

# Wait for readiness
until curl -s http://localhost:11434/api/tags > /dev/null; do
  sleep 1
done

# --- 3. PULL YOUR MODELS ---
models=(
  "gpt-oss:120b-cloud"
  "kimi-k2.5:cloud"
  "gpt-oss:20b-cloud"
  "deepseek-v3.1:671b-cloud"
  "glm-4.7:cloud"
)

for model in "${models[@]}"; do
  echo "📥 Ensuring $model is ready..."
  ollama pull "$model"
done

# --- 4. LAUNCH VIA OLLAMA ---
echo "🔧 Configuring OpenClaw default settings..."
# We use the config flag to pre-set the primary model before launching
ollama launch openclaw --config set agents.defaults.model.primary "ollama/gpt-oss:120b-cloud"
ollama launch openclaw --config set agents.defaults.workspace "$OPENCLAW_WORKSPACE_DIR"

echo "🦞 Launching OpenClaw via Ollama Bridge..."
# This starts the gateway on port 18789 and connects it to the local Ollama instance
exec ollama launch openclaw --bind 0.0.0.0
