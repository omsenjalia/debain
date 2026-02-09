#!/usr/bin/env bash
set -e
export OLLAMA_CONTEXT_LENGTH=131072

# Start Ollama in background
ollama serve &
sleep 5

echo "🦞 Launching OpenClaw..."
exec ollama launch openclaw --model gpt-oss:120b-cloud
