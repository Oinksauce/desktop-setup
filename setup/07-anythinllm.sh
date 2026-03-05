#!/usr/bin/env bash
# 07-anythinllm.sh — Install AnythingLLM as a headless Docker service.
#
# Runs at http://localhost:3001 (and http://192.168.1.110:3001 from LAN).
# Uses Docker so it runs 24/7 without needing a desktop session.
# Connects to Ollama (already running) for free local embeddings.
set -euo pipefail

STORAGE_DIR="$USER_HOME/.anythinllm"
COMPOSE_FILE="$USER_HOME/.anythinllm/docker-compose.yml"

echo "Setting up AnythingLLM (Docker)..."

# ── Install Docker Engine ──────────────────────────────────────────────────────
if command -v docker &> /dev/null; then
    echo "Docker already installed: $(docker --version)"
else
    echo "Installing Docker Engine..."
    curl -fsSL https://get.docker.com | sh
    # Add user to docker group so they can run docker without sudo
    usermod -aG docker "$INSTALL_USER"
    echo "  ✓ Docker installed"
    echo "  ⚠  Log out and back in (or run 'newgrp docker') for group change to take effect"
fi

systemctl enable docker
systemctl start docker

# ── Create storage directory ───────────────────────────────────────────────────
sudo -u "$INSTALL_USER" mkdir -p "$STORAGE_DIR"

# ── Write docker-compose.yml ───────────────────────────────────────────────────
cat > "$COMPOSE_FILE" << EOF
services:
  anythinllm:
    image: mintplexlabs/anythingllm:latest
    container_name: anythinllm
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - ${STORAGE_DIR}/storage:/app/server/storage
      - ${STORAGE_DIR}/hotdir:/app/collector/hotdir
      - ${STORAGE_DIR}/outputs:/app/collector/outputs
    environment:
      - STORAGE_DIR=/app/server/storage
      # Ollama is on the host — use host-gateway to reach it from the container
      - OLLAMA_BASE_PATH=http://host-gateway:11434
    extra_hosts:
      - "host-gateway:host-gateway"
    cap_add:
      - SYS_ADMIN
EOF
chown "$INSTALL_USER:$INSTALL_USER" "$COMPOSE_FILE"
echo "  ✓ docker-compose.yml written to $COMPOSE_FILE"

# ── Systemd service to manage the container ────────────────────────────────────
cat > /etc/systemd/system/anythinllm.service << EOF
[Unit]
Description=AnythingLLM Document Chat Service
After=network.target docker.service ollama.service
Requires=docker.service

[Service]
Type=simple
User=$INSTALL_USER
SupplementaryGroups=docker
WorkingDirectory=$STORAGE_DIR
ExecStartPre=/usr/bin/docker compose pull --quiet
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=on-failure
RestartSec=10
StandardOutput=append:$STORAGE_DIR/anythinllm.log
StandardError=append:$STORAGE_DIR/anythinllm.log

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable anythinllm
systemctl start anythinllm

# Wait for container to be ready
echo "Waiting for AnythingLLM to start (may take 30-60s on first run while pulling image)..."
for i in $(seq 1 30); do
    if curl -s --max-time 2 http://localhost:3001 > /dev/null 2>&1; then
        echo "  ✓ AnythingLLM is running at http://localhost:3001"
        break
    fi
    sleep 5
    if [ "$i" -eq 30 ]; then
        echo "  ⚠  Still starting — check: journalctl -u anythinllm -n 50"
    fi
done

echo
echo "✓ AnythingLLM setup complete"
echo
echo "  Local:    http://localhost:3001"
echo "  Network:  http://192.168.1.110:3001"
echo
echo "First-time configuration:"
echo "  1. Open http://192.168.1.110:3001 in a browser"
echo "  2. Create admin account"
echo "  3. LLM Provider: set to Ollama (http://localhost:11434) or OpenRouter/Claude API"
echo "  4. Embedding: set to Ollama → nomic-embed-text (already pulled)"
echo "  5. Create a workspace and upload documents (vault markdown, PDFs, etc.)"
echo
echo "  Logs: journalctl -u anythinllm -f"
echo "  Data: $STORAGE_DIR"
