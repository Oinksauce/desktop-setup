#!/usr/bin/env bash
# 03-claude-config.sh — Clone claude-config repo to ~/.claude and install Claude Code CLI.
set -euo pipefail

# ── Clone claude-config ────────────────────────────────────────────────────────
if [ -d "$USER_HOME/.claude/.git" ]; then
    echo "~/.claude already exists, pulling latest..."
    sudo -u "$INSTALL_USER" git -C "$USER_HOME/.claude" pull
else
    echo "Cloning claude-config to ~/.claude..."
    sudo -u "$INSTALL_USER" git clone \
        https://github.com/Oinksauce/claude-config.git \
        "$USER_HOME/.claude"
fi
echo "✓ claude-config ready at ~/.claude"

# ── Node.js and Claude Code CLI ───────────────────────────────────────────────
if command -v node &> /dev/null; then
    echo "Node.js already installed: $(node --version)"
else
    echo "Installing Node.js LTS..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt-get install -y -qq nodejs
    echo "✓ Node.js $(node --version) installed"
fi

if sudo -u "$INSTALL_USER" bash -c 'command -v claude &> /dev/null'; then
    echo "Claude Code already installed"
else
    echo "Installing Claude Code CLI..."
    sudo -u "$INSTALL_USER" npm install -g @anthropic-ai/claude-code
    echo "✓ Claude Code installed"
fi

echo
echo "✓ Claude config setup complete"
