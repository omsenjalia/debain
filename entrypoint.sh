#!/usr/bin/env bash
set -e
export OLLAMA_CONTEXT_LENGTH=131072
sudo chown -R dev:dev /home/dev/.openclaw /tmp/ollama-backups
ls -la /home/dev/.openclaw
# Start Ollama in background

echo "🦞 Launching OpenClaw..."
exec ollama serve &
