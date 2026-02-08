#!/usr/bin/env bash
set -e

# --- 1. ENVIRONMENT & PATHS ---
export OLLAMA_HOST="0.0.0.0"
export OLLAMA_MODELS="/home/dev/.ollama"
export OLLAMA_CONTEXT_LENGTH=131072
export OLLAMA_KEEP_ALIVE=24h

# OpenClaw specific paths
export OPENCLAW_STATE_DIR="/home/dev/.openclaw"
export OPENCLAW_WORKSPACE_DIR="/home/dev/openclaw/workspace"

# --- 2. START OLLAMA ---
echo "🚀 Starting Ollama..."
ollama serve &

# Wait 5 seconds for the server to initialize
sleep 5

# --- 3. PULL MODELS ---
echo "📥 Ensuring models are ready..."
ollama pull gpt-oss:120b-cloud
ollama pull kimi-k2.5:cloud
ollama pull gpt-oss:20b-cloud
ollama pull deepseek-v3.1:671b-cloud
ollama pull glm-4.7:cloud

# --- 4. LAUNCH OPENCLAW ---
echo "🦞 Launching OpenClaw via Ollama Bridge..."
# Move to app directory to ensure binary/script visibility
cd /home/dev/openclaw/app

# Launch using the specific model flag as requested
exec ollama launch openclaw --model gpt-oss:120b-cloud --bind 0.0.0.0
