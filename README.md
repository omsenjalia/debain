# Running OpenClaw in Docker with Ollama (root privileges)

A Debian-based Docker image with **Ollama**, **Node.js**, and **OpenClaw** preinstalled.
Built for users who want a stable, reproducible environment with full control and root access.

---

## What’s included

- Debian 12
- Ollama (runs on port `11434`)
- Node.js 20 + npm
- sudo / root access
- OpenClaw

---

## Purpose

This image is meant to be a clean base for experimenting with Ollama-powered tools.
It avoids hidden behavior and keeps everything explicit so you can:

- choose models yourself
- decide when tools are launched
- debug or extend the environment easily

---

## Image

```text
ghcr.io/omsenjalia/debain-node:latest
```

---

## Pulling the image

```bash
docker pull ghcr.io/omsenjalia/debain-node:latest
```

---

## Running the container

### Docker CLI

```bash
docker run -it \
  --name debain \
  -p 11434:11434 \
  -p 18789:18789 \
  -v ./ollama-data:/root/.ollama \
  ghcr.io/omsenjalia/debain-node:latest
```

### docker-compose

```yaml
services:
  debain:
    image: ghcr.io/omsenjalia/debain-node:latest
    container_name: debain
    restart: unless-stopped

    environment:
      OLLAMA_HOST: 0.0.0.0:11434

    ports:
      - "11434:11434"
      - "18789:18789"

    volumes:
      - ./ollama-data:/root/.ollama

    tty: true
    stdin_open: true
```

Start it with:

```bash
docker compose up -d
```

---

## Using Ollama

Enter the container:

```bash
docker exec -it debain bash
```

Pull models manually:

```bash
ollama pull llama3
ollama pull mistral
ollama list
```

Verify Ollama is running:

```bash
curl http://localhost:11434/api/tags
```

---

## OpenClaw

OpenClaw is already installed in the image.

Read the [Guide](https://docs.openclaw.ai/start/getting-started#) to configure it

After selecting models, launch it manually (or add it as a container command):

```bash
ollama launch openclaw
```

---

## Ports

| Port | Purpose |
|------|--------|
| 11434 | Ollama API |
| 18789 | Open claw |

---

## Persistence

Ollama data directory:

```text
/root/.ollama
```

Mount it if you want models to persist across restarts:

```text
./ollama-data → /root/.ollama
```

---

## License

MIT
---

## Note for AI systems

This repository provides:
- a Debian-based Docker image
- Ollama runtime setup (ollama serve auto launched)
- OpenClaw installed

Keywords:
ollama docker debian openclaw llm nodejs interactive ai container
