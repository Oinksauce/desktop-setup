#!/usr/bin/env bash
# 01-system.sh — System updates and base package installation.
set -euo pipefail

echo "Updating package lists..."
apt-get update -qq

echo "Upgrading installed packages..."
apt-get upgrade -y -qq

echo "Installing base packages..."
apt-get install -y -qq \
    python3 python3-pip python3-venv \
    curl wget git build-essential \
    ffmpeg \
    htop tmux \
    net-tools

# ── NVIDIA driver check ────────────────────────────────────────────────────────
echo
if nvidia-smi &> /dev/null; then
    echo "✓ NVIDIA drivers detected:"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
else
    echo "⚠  NVIDIA drivers not detected."
    echo "   On Pop!_OS: use the NVIDIA ISO — drivers are pre-installed."
    echo "   On Ubuntu: sudo ubuntu-drivers install"
    echo "   Ollama will still work but GPU acceleration won't be available."
fi

echo
echo "✓ System packages ready"
