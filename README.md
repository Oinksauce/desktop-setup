# desktop-setup

One-command bootstrap for Jon's Linux desktop environment (Pop!_OS / Ubuntu 22.04+).

Sets up:
- **Ollama** — local AI model server with NVIDIA GPU support
- **SBS RAG service** — semantic search over Stronger by Science articles (port 8765)
- **Discord vault bot** — Claude Code bot that reads/edits the Obsidian vault via Discord
- **Claude Code CLI** — with full claude-config (scripts, skills, settings)

---

## Prerequisites

- Fresh Pop!_OS (NVIDIA ISO recommended) or Ubuntu 22.04+ install
- NVIDIA drivers installed (Pop!_OS NVIDIA ISO includes them; Ubuntu: `sudo ubuntu-drivers install`)
- Internet connection
- Your Discord bot token and channel ID (for the bot service)

---

## Quick Start

```bash
git clone https://github.com/Oinksauce/desktop-setup.git
cd desktop-setup
sudo bash install.sh
```

That's it. The script detects your username from `$SUDO_USER` and installs everything under your home directory.

---

## What Gets Installed

| Component | Location | Service |
|---|---|---|
| claude-config (scripts + skills) | `~/.claude/` | — |
| Claude Code CLI | `~/.npm-global/bin/claude` | — |
| Ollama | `/usr/local/bin/ollama` | `ollama` |
| RAG service venv | `~/sbs-rag/venv/` | `sbs-rag` |
| RAG ChromaDB data | `~/sbs-rag/chroma/` | — |
| Discord bot venv | `~/.claude/venvs/discord-bot/` | `discord-bot` |

---

## Discord Bot Setup

The Discord bot requires a secrets file before its service will start.

1. Copy the template:
   ```bash
   cp config/example.env ~/.claude/scripts/.discord-vault-bot.env
   nano ~/.claude/scripts/.discord-vault-bot.env
   ```

2. Fill in:
   - `DISCORD_BOT_TOKEN` — from [Discord Developer Portal](https://discord.com/developers)
   - `DISCORD_CHANNEL_ID` — right-click the channel in Discord → Copy Channel ID
   - `VAULT_PATH` — where Obsidian Sync puts the vault (e.g. `/home/jon/Documents/JonVaultSyn`)

3. Start the service:
   ```bash
   sudo systemctl start discord-bot
   ```

If the env file is missing when `install.sh` runs, the bot step is skipped gracefully — just run step 5 manually after creating the file:
```bash
sudo bash setup/05-discord-bot.sh
```

---

## Vault Sync (Obsidian Sync — required for Discord bot)

The Discord bot runs `claude -p` against vault files on disk. Obsidian Sync keeps the vault current across all your devices — Mac, Linux desktop, phone.

`install.sh` installs Obsidian and adds it to autostart. After that, two manual steps:

**1. Enable auto-login**

Obsidian Sync only runs while Obsidian is open. Auto-login ensures Obsidian starts at boot even with nobody at the keyboard:

- GNOME Settings → Users → Automatic Login → ON
- Or via config: edit `/etc/gdm3/custom.conf`:
  ```ini
  [daemon]
  AutomaticLoginEnable=true
  AutomaticLogin=jon
  ```
  Then: `sudo systemctl restart gdm`

**2. Sign into Obsidian Sync**

On first login, Obsidian launches automatically. Then:
1. Settings → Sync → Sign in with your Obsidian account
2. Connect to the **JonVaultSyn** remote vault
3. Wait for initial sync to complete (may take a few minutes for 400+ articles)
4. Note the vault path Obsidian chose (typically `~/Documents/JonVaultSyn`)

**3. Update the Discord bot env file**

```bash
nano ~/.claude/scripts/.discord-vault-bot.env
# Set: VAULT_PATH=/home/jon/Documents/JonVaultSyn
sudo systemctl restart discord-bot
```

---

## AnythingLLM

AnythingLLM runs as a Docker container — no desktop session needed, accessible from any device on the LAN.

- **URL:** `http://192.168.1.110:3001`
- **Storage:** `~/.anythinllm/`
- **Service:** `anythinllm` (systemd, managed via docker compose)

**First-time setup** (in browser at `http://192.168.1.110:3001`):

1. Create admin account
2. **LLM Provider** — choose one:
   - *Ollama* → `http://localhost:11434` (free, local, good for most tasks)
   - *OpenRouter* → API key from openrouter.ai (many free cloud models)
   - *Anthropic* → Claude API key (best reasoning, API-billed)
3. **Embedding model** → Ollama → `nomic-embed-text` (already pulled, free)
4. Create a workspace, upload documents, start chatting

**Useful workspaces to create:**
- Westford meeting minutes (after marker-pdf conversion on M5)
- Legal documents
- SBS articles (alternative to the custom RAG service)

**Logs:** `journalctl -u anythinllm -f`

---

## Post-Install: Re-index RAG

After the RAG service is running, send the vault articles to it from your Mac:

```bash
python3 ~/.claude/scripts/sbs/rag_index.py
```

Verify it worked:
```bash
curl http://192.168.1.110:8765/health
```

---

## Updating

When claude-config scripts change (e.g. after a `git push` from the Mac), pull and restart:

```bash
sudo bash scripts/update.sh
```

The RAG service symlinks directly to `~/.claude/scripts/sbs/rag_service.py`, so it picks up changes on restart automatically.

---

## Service Management

```bash
# Status
systemctl status ollama sbs-rag discord-bot

# Logs (live)
journalctl -u sbs-rag -f
journalctl -u discord-bot -f

# Restart after config changes
sudo systemctl restart sbs-rag
sudo systemctl restart discord-bot
```

---

## Dual Boot Notes

If dual-booting with Windows:
- Disable **Fast Startup** in Windows before installing Linux (Settings → Power → Fast Startup off)
- Get your **BitLocker recovery key** from account.microsoft.com before resizing partitions
- Disable **Secure Boot** in BIOS, or configure it to allow the Linux bootloader
- Shrink the Windows partition first from Windows Disk Management, then let the Linux installer use the free space
- Recommended split (2TB drive): ~250GB Windows / ~1.75TB Linux

---

## Repo Structure

```
desktop-setup/
├── install.sh              # Main entry point — run this
├── setup/
│   ├── 01-system.sh        # apt updates, NVIDIA check
│   ├── 02-ollama.sh        # Install Ollama, pull models
│   ├── 03-claude-config.sh # Clone claude-config, install Claude Code
│   ├── 04-rag.sh           # SBS RAG service
│   └── 05-discord-bot.sh   # Discord vault bot
├── services/
│   ├── sbs-rag.service     # systemd unit (templated)
│   └── discord-bot.service # systemd unit (templated)
├── config/
│   └── example.env         # Template for Discord bot secrets
└── scripts/
    └── update.sh           # Pull latest + restart services
```
