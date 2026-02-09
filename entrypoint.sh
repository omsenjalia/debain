#!/usr/bin/env bash
set -e
export OLLAMA_CONTEXT_LENGTH=131072
sudo chown -R dev:dev /home/dev/.openclaw /tmp/ollama-backups
ls -la /home/dev/.openclaw
# Start Ollama in background
ollama serve &
sleep 5

echo "🦞 Launching OpenClaw..."
exec openclaw gateway run --model ollama/gpt-oss:120b-cloud --bind lan --port 18789 --allow-unconfigured
