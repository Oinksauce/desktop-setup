#!/usr/bin/env bash
# 05-discord-bot.sh — Set up the Discord vault bot as a systemd service.
set -euo pipefail

VENV_DIR="$USER_HOME/.claude/venvs/discord-bot"
BOT_SCRIPT="$USER_HOME/.claude/scripts/discord-vault-bot.py"
ENV_FILE="$USER_HOME/.claude/scripts/.discord-vault-bot.env"

echo "Setting up Discord vault bot..."

# ── Fix ownership of ~/.claude in case prior runs created root-owned files ─────
chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.claude"

# ── Check for env file ─────────────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
    echo "  ⚠  Env file not found: $ENV_FILE"
    echo
    echo "  Create it from the template:"
    echo "    cp $SCRIPT_DIR/config/example.env $ENV_FILE"
    echo "    nano $ENV_FILE"
    echo
    echo "  Then re-run this script or start the service manually:"
    echo "    sudo bash $SCRIPT_DIR/setup/05-discord-bot.sh"
    echo
    echo "  Skipping Discord bot service installation."
    exit 0
fi

# ── Verify bot script is present ──────────────────────────────────────────────
if [ ! -f "$BOT_SCRIPT" ]; then
    echo "✗ $BOT_SCRIPT not found."
    echo "  Run setup/03-claude-config.sh first."
    exit 1
fi

# ── Python venv ────────────────────────────────────────────────────────────────
sudo -u "$INSTALL_USER" mkdir -p "$USER_HOME/.claude/venvs"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python venv at $VENV_DIR..."
    sudo -u "$INSTALL_USER" python3 -m venv "$VENV_DIR"
fi

echo "Installing Discord bot dependencies..."
sudo -u "$INSTALL_USER" "$VENV_DIR/bin/pip" install --upgrade pip --quiet
sudo -u "$INSTALL_USER" "$VENV_DIR/bin/pip" install \
    "discord.py" \
    aiohttp \
    faster-whisper \
    --quiet
echo "  ✓ packages installed"

# ── Create log directory ───────────────────────────────────────────────────────
sudo -u "$INSTALL_USER" mkdir -p "$USER_HOME/.claude/logs"

# ── Install systemd service ────────────────────────────────────────────────────
echo "Installing discord-bot systemd service..."
sed \
    "s|__USER__|$INSTALL_USER|g; s|__USER_HOME__|$USER_HOME|g" \
    "$SCRIPT_DIR/services/discord-bot.service" \
    > /etc/systemd/system/discord-bot.service

systemctl daemon-reload
systemctl enable discord-bot
systemctl restart discord-bot

sleep 2
if systemctl is-active --quiet discord-bot; then
    echo "  ✓ discord-bot service started"
else
    echo "  ⚠  discord-bot may have failed to start"
    echo "     Check: journalctl -u discord-bot -n 50"
fi

echo
echo "✓ Discord bot setup complete"
echo "  Status: systemctl status discord-bot"
echo "  Logs:   journalctl -u discord-bot -f"
