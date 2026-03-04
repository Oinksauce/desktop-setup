#!/usr/bin/env bash
# install.sh — Bootstrap the desktop Linux environment.
#
# Run as root (or with sudo) on a fresh Pop!_OS / Ubuntu 22.04+ install:
#   sudo bash install.sh
#
# Safe to re-run — each step checks before acting.

set -euo pipefail

# ── Detect the real user (not root) ───────────────────────────────────────────
if [ -n "${SUDO_USER:-}" ]; then
    INSTALL_USER="$SUDO_USER"
elif [ "$(id -u)" -ne 0 ]; then
    INSTALL_USER="$(whoami)"
else
    echo "ERROR: Run with sudo, not as root directly."
    echo "  sudo bash install.sh"
    exit 1
fi
USER_HOME=$(eval echo "~$INSTALL_USER")
export INSTALL_USER USER_HOME

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

echo "=== Desktop Setup ==="
echo "Installing for user: $INSTALL_USER ($USER_HOME)"
echo

# ── Run setup steps ────────────────────────────────────────────────────────────
run_step() {
    local name="$1" script="$2"
    echo "──────────────────────────────────────────"
    echo "Step: $name"
    echo "──────────────────────────────────────────"
    bash "$SCRIPT_DIR/setup/$script"
    echo
}

run_step "System packages"        01-system.sh
run_step "Ollama + GPU"           02-ollama.sh
run_step "Claude config & CLI"    03-claude-config.sh
run_step "SBS RAG service"        04-rag.sh
run_step "Discord vault bot"      05-discord-bot.sh
run_step "Syncthing vault sync"   06-syncthing.sh

echo "══════════════════════════════════════════"
echo "Setup complete!"
echo
echo "Service status:"
systemctl is-active --quiet sbs-rag                       && echo "  ✓ sbs-rag"      || echo "  ✗ sbs-rag (check: journalctl -u sbs-rag -n 50)"
systemctl is-active --quiet discord-bot                   && echo "  ✓ discord-bot"  || echo "  ✗ discord-bot (check: journalctl -u discord-bot -n 50)"
systemctl is-active --quiet "syncthing@${INSTALL_USER}"   && echo "  ✓ syncthing"    || echo "  ✗ syncthing (check: journalctl -u syncthing@${INSTALL_USER} -n 50)"
echo
echo "Next steps:"
echo "  1. Pair Syncthing with Mac (see instructions above) — vault must sync before bot works"
echo "  2. Set VAULT_PATH in ~/.claude/scripts/.discord-vault-bot.env"
echo "  3. Restart Discord bot after vault is synced: sudo systemctl restart discord-bot"
echo "  4. Re-index RAG from Mac: python3 ~/.claude/scripts/sbs/rag_index.py"
echo "  5. Verify RAG: curl http://localhost:8765/health"
