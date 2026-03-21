#!/usr/bin/env bash
# 05-discord-bot.sh — Set up the Discord vault bot (Claude Code Channels plugin).
set -euo pipefail

ENV_FILE="$USER_HOME/.claude/channels/discord/.env"
ENV_TEMPLATE="$SCRIPT_DIR/config/example.env"

echo "Setting up Discord vault bot (Claude Code Channels)..."

# ── Fix ownership of ~/.claude in case prior runs created root-owned files ─────
[ -d "$USER_HOME/.claude" ] && chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.claude"

# ── Install Bun (required by the Discord plugin's MCP server) ─────────────────
if ! sudo -u "$INSTALL_USER" bash -c "source \"\$HOME/.bashrc\" 2>/dev/null; command -v bun" &>/dev/null; then
    echo "Installing Bun..."
    sudo -u "$INSTALL_USER" bash -c 'curl -fsSL https://bun.sh/install | bash'
    echo "  ✓ Bun installed"
else
    echo "  ✓ Bun already installed"
fi

# ── Check for env file ─────────────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
    echo "  ⚠  Env file not found: $ENV_FILE"
    echo
    echo "  Create it from the template:"
    echo "    mkdir -p $(dirname "$ENV_FILE")"
    echo "    cp $ENV_TEMPLATE $ENV_FILE"
    echo "    nano $ENV_FILE   # paste your DISCORD_BOT_TOKEN"
    echo
    echo "  Then re-run this script or complete setup manually."
    echo
    echo "  Skipping Discord bot service installation."
    exit 0
fi

# ── Verify Claude Code is installed ───────────────────────────────────────────
CLAUDE_BIN="$USER_HOME/.local/bin/claude"
if [ ! -x "$CLAUDE_BIN" ]; then
    echo "✗ Claude Code not found at $CLAUDE_BIN"
    echo "  Run setup/03-claude-config.sh first, or check the install path with: which claude"
    exit 1
fi

# ── Install systemd service ────────────────────────────────────────────────────
echo "Installing discord-bot systemd service..."
sed \
    "s|__USER__|$INSTALL_USER|g; s|__USER_HOME__|$USER_HOME|g" \
    "$SCRIPT_DIR/services/discord-bot.service" \
    > /etc/systemd/system/discord-bot.service

systemctl daemon-reload
systemctl enable discord-bot
# Do NOT start the service yet — the plugin must be installed and paired interactively first.

echo
echo "✓ Discord bot service installed and enabled (not yet started)"
echo
echo "  REQUIRED: Complete the one-time interactive setup before starting:"
echo "    1. On the desktop as $INSTALL_USER, run:"
echo "       claude"
echo "       /plugin install discord@claude-plugins-official"
echo "       /discord:configure \$(grep DISCORD_BOT_TOKEN $ENV_FILE | cut -d= -f2)"
echo "    2. Run: claude --channels plugin:discord@claude-plugins-official"
echo "    3. DM the bot on Discord to get a pairing code"
echo "    4. In Claude: /discord:access pair <code>"
echo "    5. In Claude: /discord:access policy allowlist"
echo "    6. Verify: cat ~/.claude/channels/discord/access.json"
echo "    7. Exit and start the service: sudo systemctl start discord-bot"
echo
echo "  Status: systemctl status discord-bot"
echo "  Logs:   journalctl -u discord-bot -f"
