#!/usr/bin/env bash
# 04-rag.sh — Set up the SBS RAG semantic search service (native Linux).
#
# Simpler than the WSL2 version: Ollama is on localhost, no gateway detection needed.
set -euo pipefail

RAG_DIR="$USER_HOME/sbs-rag"
VENV_DIR="$RAG_DIR/venv"
CHROMA_DIR="$RAG_DIR/chroma"
SERVICE_SCRIPT="$USER_HOME/.claude/scripts/sbs/rag_service.py"
PORT=8765

echo "Setting up SBS RAG service..."

# ── Verify claude-config is present ───────────────────────────────────────────
if [ ! -f "$SERVICE_SCRIPT" ]; then
    echo "✗ $SERVICE_SCRIPT not found."
    echo "  Run setup/03-claude-config.sh first."
    exit 1
fi

# ── Create directories ─────────────────────────────────────────────────────────
mkdir -p "$CHROMA_DIR"
chown -R "$INSTALL_USER:$INSTALL_USER" "$RAG_DIR"

# ── Python venv ────────────────────────────────────────────────────────────────
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python venv at $VENV_DIR..."
    sudo -u "$INSTALL_USER" python3 -m venv "$VENV_DIR"
fi

echo "Installing RAG dependencies..."
sudo -u "$INSTALL_USER" "$VENV_DIR/bin/pip" install --upgrade pip --quiet
sudo -u "$INSTALL_USER" "$VENV_DIR/bin/pip" install \
    fastapi \
    "uvicorn[standard]" \
    chromadb \
    --quiet
echo "  ✓ packages installed"

# ── Symlink service script ─────────────────────────────────────────────────────
# Symlink so git pull on claude-config automatically updates the running service
sudo -u "$INSTALL_USER" ln -sf "$SERVICE_SCRIPT" "$RAG_DIR/rag_service.py"
echo "  ✓ symlinked rag_service.py from claude-config"

# ── Open firewall port ─────────────────────────────────────────────────────────
if command -v ufw &> /dev/null; then
    ufw allow ${PORT}/tcp > /dev/null 2>&1
    echo "  ✓ ufw: port ${PORT} open for RAG service"
fi

# ── Install systemd service ────────────────────────────────────────────────────
echo "Installing sbs-rag systemd service..."
sed \
    "s|__USER__|$INSTALL_USER|g; s|__USER_HOME__|$USER_HOME|g" \
    "$SCRIPT_DIR/services/sbs-rag.service" \
    > /etc/systemd/system/sbs-rag.service

systemctl daemon-reload
systemctl enable sbs-rag
systemctl restart sbs-rag

# ── Verify ─────────────────────────────────────────────────────────────────────
sleep 3
if curl -s --max-time 5 "http://localhost:${PORT}/health" > /dev/null 2>&1; then
    HEALTH=$(curl -s "http://localhost:${PORT}/health")
    echo "  ✓ Health check passed: $HEALTH"
else
    echo "  ⚠  Service not responding yet (may still be starting)"
    echo "     Check: journalctl -u sbs-rag -n 50"
fi

echo
echo "✓ RAG service setup complete"
echo "  Status:  systemctl status sbs-rag"
echo "  Logs:    journalctl -u sbs-rag -f"
echo "  Health:  curl http://localhost:${PORT}/health"
echo
echo "After setup, re-index from Mac:"
echo "  python3 ~/.claude/scripts/sbs/rag_index.py"
