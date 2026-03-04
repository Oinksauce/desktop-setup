#!/usr/bin/env bash
# update.sh — Pull latest claude-config and restart affected services.
#
# Usage: sudo bash scripts/update.sh
set -euo pipefail

if [ -n "${SUDO_USER:-}" ]; then
    INSTALL_USER="$SUDO_USER"
else
    INSTALL_USER="$(whoami)"
fi
USER_HOME=$(eval echo "~$INSTALL_USER")

echo "Pulling latest claude-config..."
sudo -u "$INSTALL_USER" git -C "$USER_HOME/.claude" pull

echo "Restarting services..."
systemctl restart sbs-rag
systemctl restart discord-bot

echo
systemctl is-active --quiet sbs-rag     && echo "  ✓ sbs-rag running"      || echo "  ✗ sbs-rag failed"
systemctl is-active --quiet discord-bot && echo "  ✓ discord-bot running"  || echo "  ✗ discord-bot failed"
echo
echo "Done. RAG and bot are running the latest scripts from claude-config."
