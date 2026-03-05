#!/usr/bin/env bash
# 03-claude-config.sh — Clone claude-config repo to ~/.claude and install Claude Code CLI.
set -euo pipefail

# ── Git credential caching (enter token once) ─────────────────────────────────
sudo -u "$INSTALL_USER" git config --global credential.helper store
echo "✓ Git credentials set to persist (~/.git-credentials)"

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

# ── Node.js ───────────────────────────────────────────────────────────────────
if command -v node &> /dev/null; then
    echo "Node.js already installed: $(node --version)"
else
    echo "Installing Node.js LTS..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt-get install -y -qq nodejs
    echo "✓ Node.js $(node --version) installed"
fi

# ── Configure npm prefix to user-local dir (avoids permission errors) ─────────
sudo -u "$INSTALL_USER" npm config set prefix "$USER_HOME/.local"
echo "✓ npm global prefix set to ~/.local"

# ── Add ~/.local/bin to PATH in .bashrc if not already present ────────────────
BASHRC="$USER_HOME/.bashrc"
if ! grep -q '\.local/bin' "$BASHRC" 2>/dev/null; then
    echo '' >> "$BASHRC"
    echo '# npm global binaries' >> "$BASHRC"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
    echo "✓ Added ~/.local/bin to PATH in .bashrc"
fi

# ── Claude Code CLI ───────────────────────────────────────────────────────────
if [ -f "$USER_HOME/.local/bin/claude" ]; then
    echo "Claude Code already installed"
else
    echo "Installing Claude Code CLI..."
    sudo -u "$INSTALL_USER" \
        PATH="$USER_HOME/.local/bin:$PATH" \
        npm install -g @anthropic-ai/claude-code
    echo "✓ Claude Code installed"
fi

echo
echo "✓ Claude config setup complete"
