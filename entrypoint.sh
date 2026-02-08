#!/usr/bin/env bash
set -e

# --- 1. SET GLOBAL DEFAULTS ---
# Force Ollama to use 128k context (131072 tokens) for all models
export OLLAMA_CONTEXT_LENGTH=131072
# Ensure Ollama keeps models in memory for 24 hours to avoid reload delay
export OLLAMA_KEEP_ALIVE=24h

# --- 2. START OLLAMA ---
echo "🚀 Starting Ollama server in background..."
ollama serve > /dev/null 2>&1 &
SERVER_PID=$!

# Wait for Ollama to wake up
echo "⏳ Waiting for Ollama to be ready..."
until curl -s http://localhost:11434/api/tags > /dev/null; do
  sleep 1
done
echo "✅ Ollama is online."

# --- 3. PRE-LOAD MODELS ---
# We use the :cloud suffix as requested for off-loaded high-performance compute
echo "📥 Pulling required models (this may take a moment)..."
ollama pull gpt-oss:120b-cloud
ollama pull kimi-k2.5:cloud
ollama pull gpt-oss:20b-cloud
ollama pull deepseek-v3.1:671b-cloud
ollama pull glm-4.7:cloud

# --- 4. CONFIGURE OPENCLAW ---
# Set the default model via the CLI so the Web UI starts with it selected
echo "🔧 Configuring OpenClaw default model..."
# We use gpt-oss:120b-cloud as the primary engine
openclaw config set agents.defaults.model.primary "ollama/gpt-oss:120b-cloud"

# Ensure the context length is also communicated to OpenClaw's internal agent config
# Note: OpenClaw 2026 uses a specific environment variable for session context
export OPENCLAW_SESSION_CONTEXT=131072

# --- 5. LAUNCH ---
echo "🦞 Launching OpenClaw Gateway..."
# Exec ensures OpenClaw catches termination signals (Ctrl+C / Docker Stop)
exec ollama launch openclaw
