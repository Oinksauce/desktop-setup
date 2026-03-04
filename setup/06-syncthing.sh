#!/usr/bin/env bash
# 06-syncthing.sh — Install Syncthing and configure vault sync from Mac.
#
# Syncthing runs as a system service, syncing continuously with no UI needed.
# One-time manual step required after this script: pair with the Mac via web UI.
set -euo pipefail

VAULT_DIR="$USER_HOME/Documents/JonVaultSyn"

echo "Setting up Syncthing..."

# ── Install Syncthing ──────────────────────────────────────────────────────────
if command -v syncthing &> /dev/null; then
    echo "Syncthing already installed: $(syncthing --version | head -1)"
else
    echo "Installing Syncthing..."
    # Official Syncthing apt repo
    curl -fsSL https://syncthing.net/release-key.gpg \
        | gpg --dearmor -o /usr/share/keyrings/syncthing-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] \
https://apt.syncthing.net/ syncthing stable" \
        > /etc/apt/sources.list.d/syncthing.list
    apt-get update -qq
    apt-get install -y -qq syncthing
    echo "  ✓ Syncthing installed"
fi

# ── Create vault directory ─────────────────────────────────────────────────────
sudo -u "$INSTALL_USER" mkdir -p "$VAULT_DIR"

# ── Enable and start Syncthing as a system service for the user ───────────────
# Uses the official systemd template unit: syncthing@<user>
systemctl enable "syncthing@${INSTALL_USER}"
systemctl start  "syncthing@${INSTALL_USER}"

sleep 2
if systemctl is-active --quiet "syncthing@${INSTALL_USER}"; then
    echo "  ✓ Syncthing service running"
else
    echo "  ✗ Syncthing failed to start. Check: journalctl -u syncthing@${INSTALL_USER} -n 50"
    exit 1
fi

# ── Print device ID for pairing ────────────────────────────────────────────────
echo
echo "══════════════════════════════════════════════════════"
echo "  Syncthing is running. One-time pairing required."
echo "══════════════════════════════════════════════════════"
echo
echo "This machine's Syncthing Device ID:"
sudo -u "$INSTALL_USER" syncthing --device-id 2>/dev/null || \
    echo "  (Run 'syncthing --device-id' as $INSTALL_USER to get it)"
echo
echo "Steps to pair with the Mac:"
echo "  1. On the Mac, open Syncthing UI: http://localhost:8384"
echo "     (or: syncthing serve --no-browser & then visit the URL)"
echo "  2. Click 'Add Remote Device' and enter this machine's Device ID"
echo "  3. On this machine, open http://localhost:8384 and accept the Mac's connection"
echo "  4. On the Mac, share the vault folder with this device:"
echo "     Folders → JonVaultSyn → Edit → Sharing → check this device"
echo "  5. On this machine, accept the folder and set path to: $VAULT_DIR"
echo
echo "After pairing, the vault syncs automatically whenever both machines are online."
echo "Vault path for discord-bot env: VAULT_PATH=$VAULT_DIR"
