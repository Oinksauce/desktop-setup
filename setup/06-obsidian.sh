#!/usr/bin/env bash
# 06-obsidian.sh — Install Obsidian and configure it to autostart on login.
#
# Obsidian Sync runs inside the Obsidian app, so Obsidian must be running for
# the vault to stay in sync. On an always-on desktop with auto-login, adding
# Obsidian to autostart is all that's needed.
set -euo pipefail

AUTOSTART_DIR="$USER_HOME/.config/autostart"

echo "Installing Obsidian..."

# ── Install Obsidian .deb (latest release from GitHub) ────────────────────────
if command -v obsidian &> /dev/null; then
    echo "Obsidian already installed"
else
    echo "Fetching latest Obsidian release..."
    LATEST=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
        | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])")
    VERSION="${LATEST#v}"
    DEB_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/${LATEST}/obsidian_${VERSION}_amd64.deb"
    DEB_FILE="/tmp/obsidian_${VERSION}_amd64.deb"

    echo "  Downloading Obsidian ${VERSION}..."
    curl -sL "$DEB_URL" -o "$DEB_FILE"
    apt-get install -y "$DEB_FILE" -qq
    rm -f "$DEB_FILE"
    echo "  ✓ Obsidian ${VERSION} installed"
fi

# ── Autostart on login ─────────────────────────────────────────────────────────
# Creates an XDG autostart entry so Obsidian starts when the desktop session loads.
# Requires auto-login to be enabled (see note below).
sudo -u "$INSTALL_USER" mkdir -p "$AUTOSTART_DIR"
cat > "$AUTOSTART_DIR/obsidian.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Obsidian
Exec=obsidian --no-sandbox
Icon=obsidian
Comment=Obsidian — start on login to keep Obsidian Sync active
X-GNOME-Autostart-enabled=true
Hidden=false
EOF
chown "$INSTALL_USER:$INSTALL_USER" "$AUTOSTART_DIR/obsidian.desktop"
echo "  ✓ Obsidian added to autostart"

echo
echo "✓ Obsidian setup complete"
echo
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  IMPORTANT: Auto-login required for Obsidian Sync to work  │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│  Enable auto-login so Obsidian starts when the machine      │"
echo "│  boots, even without someone sitting at the keyboard:       │"
echo "│                                                              │"
echo "│  Settings → Users → Automatic Login → ON                    │"
echo "│  (GNOME Settings, or: gdm auto-login in /etc/gdm3/custom.conf) │"
echo "└─────────────────────────────────────────────────────────────┘"
echo
echo "After first login:"
echo "  1. Open Obsidian — it will launch automatically"
echo "  2. Sign into Obsidian Sync (Settings → Sync)"
echo "  3. Connect to the JonVaultSyn vault"
echo "  4. Wait for initial sync to complete"
echo "  5. Update VAULT_PATH in ~/.claude/scripts/.discord-vault-bot.env:"
echo "     VAULT_PATH=$USER_HOME/Documents/JonVaultSyn"
echo "     (or wherever Obsidian Sync places the vault)"
echo "  6. sudo systemctl restart discord-bot"
