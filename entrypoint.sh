#!/usr/bin/env bash
set -e

export OLLAMA_HOST="0.0.0.0"
export OLLAMA_MODELS="/home/dev/.ollama"
export OLLAMA_CONTEXT_LENGTH=131072

# Start Ollama in background
ollama serve &
sleep 2

echo "🦞 Launching OpenClaw..."
exec ollama launch openclaw --model gpt-oss:120b-cloud --bind 0.0.0.0
