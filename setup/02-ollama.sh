#!/usr/bin/env bash
# 02-ollama.sh — Install Ollama and pull required models.
set -euo pipefail

# ── Install Ollama ─────────────────────────────────────────────────────────────
if command -v ollama &> /dev/null; then
    echo "Ollama already installed: $(ollama --version)"
else
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo "✓ Ollama installed"
fi

# ── Enable and start Ollama service ───────────────────────────────────────────
systemctl enable ollama
systemctl start ollama

# Wait for Ollama to be ready
echo "Waiting for Ollama to start..."
for i in $(seq 1 15); do
    if curl -s --max-time 2 http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✓ Ollama is running"
        break
    fi
    sleep 2
    if [ "$i" -eq 15 ]; then
        echo "✗ Ollama did not start in time. Check: journalctl -u ollama -n 50"
        exit 1
    fi
done

# ── GPU check ─────────────────────────────────────────────────────────────────
echo
GPU_INFO=$(curl -s http://localhost:11434/api/tags 2>/dev/null || echo "")
if nvidia-smi &> /dev/null; then
    echo "✓ GPU available — Ollama will use NVIDIA GPU"
    echo "  Verify with: ollama ps  (while a model is running)"
else
    echo "⚠  No GPU detected — Ollama will run on CPU only"
fi

# ── Pull required models ───────────────────────────────────────────────────────
echo
echo "Pulling required models (this may take a while)..."

# Required for RAG service
echo "  Pulling nomic-embed-text (embedding model for RAG)..."
ollama pull nomic-embed-text

# Primary inference models
echo "  Pulling qwen3-coder:30b (primary code/reasoning model)..."
ollama pull qwen3-coder:30b

echo
echo "Optional models (uncomment in this script to pull):"
echo "  # ollama pull deepseek-r1:8b"
echo "  # ollama pull qwen3:8b"
echo
echo "✓ Ollama setup complete"
echo "  Service: systemctl status ollama"
echo "  Models:  ollama list"
