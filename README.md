# Hermes Agent + Ollama on Google Cloud

[![Ollama](https://img.shields.io/badge/Ollama-v0.3.0-blue)](https://ollama.com)
[![Hermes Agent](https://img.shields.io/badge/Hermes_Agent-v2.0-orange)](https://github.com/NousResearch/hermes-agent)
[![Google Cloud](https://img.shields.io/badge/Google_Cloud-Compute_Engine-4285F4)](https://cloud.google.com/compute)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**A complete, beginner-friendly guide for running Hermes Agent with local Ollama models on Google Cloud VMs, accessible from Android phones via Termux.**

---

## Overview

This project provides **step-by-step documentation** for Android users to:
1. Set up a **Google Cloud VM** (free-tier eligible)
2. Connect from **Android via Termux**
3. Install **Hermes Agent** and **Ollama**
4. Download and use **local Ollama models**
5. Configure everything to work together

**Key Features:**
- ✅ **No paid API costs** - Uses local models via Ollama
- ✅ **Android-friendly** - Designed for Termux on phones
- ✅ **Free-tier compatible** - Works within Google Cloud's free tier (with caveats)
- ✅ **Temporary storage optimized** - Uses `/tmp` for models to avoid permanent clutter
- ✅ **Beginner-focused** - Clear, copy-paste friendly commands

---

## Architecture

```
Android Phone (Termux)
        ↓ (SSH)
Google Cloud VM (Ubuntu/Debian)
        ↓ (Install)
    Hermes Agent + Ollama
        ↓ (Local Model)
    Ollama Model (e.g., qwen2.5:1.5b in /tmp/ollama_models)
```

| **Component**       | **Location**          | **Purpose**                                                                 |
|---------------------|-----------------------|-----------------------------------------------------------------------------|
| Android Phone       | Local                 | Runs Termux for SSH access to the VM                                       |
| Termux             | Android               | Terminal emulator with SSH client                                         |
| Google Cloud VM    | Cloud                 | Hosts Hermes Agent and Ollama (Ubuntu 22.04 recommended)                  |
| Hermes Agent       | VM (`~/.hermes`)      | AI agent framework that uses Ollama for inference                         |
| Ollama             | VM (`~/.local/bin`)   | Local LLM inference server                                                  |
| Ollama Models      | VM (`/tmp/ollama_models`) | Downloaded models (temporary storage)                                   |

---

## Quick Start

For **Android users**, follow the complete guide:

📖 **[Full Android Setup Guide](docs/ANDROID_GUIDE.md)**

### TL;DR (For Quick Testing)

1. **Create a Google Cloud VM** (e2-medium, 4GB RAM, Ubuntu 22.04)
2. **Connect via Termux SSH**
3. **Run the setup commands**:
   ```bash
   # Install dependencies
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y zstd curl git python3 python3-pip
   
   # Install Ollama
   curl -fsSL https://ollama.com/install.sh | sh
   export PATH="$HOME/.local/bin:$PATH"
   
   # Configure model storage in /tmp
   export OLLAMA_MODELS=/tmp/ollama_models
   mkdir -p "$OLLAMA_MODELS"
   
   # Install Hermes Agent
   curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
   exec bash
   
   # Pull a lightweight model
   ollama pull qwen2.5:1.5b
   ollama serve &
   
   # Configure Hermes
   hermes setup
   # Select: Custom endpoint → http://127.0.0.1:11434/v1 → qwen2.5:1.5b
   
   # Start chatting
   hermes
   ```

---

## Documentation

| **Guide** | **Description** | **Audience** |
|-----------|----------------|--------------|
| **[Android Guide](docs/ANDROID_GUIDE.md)** | Complete setup for Android/Termux users | **Main guide** for this repo |
| [Setup Guide](docs/SETUP_GUIDE.md) | Google Cloud Shell setup (legacy) | Cloud Shell users |
| [Architecture](docs/ARCHITECTURE.md) | Storage limits and workflow | Advanced users |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues and fixes | All users |

---

## Free Tier and Billing

> **⚠️ CRITICAL: Google Cloud is NOT permanently free.**

### Free Tier Limits

| **Resource** | **Free Tier** | **Notes** |
|--------------|---------------|-----------|
| Compute Engine | 1 x e2-micro/month | **Not enough for Ollama models** |
| Compute Engine | e2-medium (4GB RAM) | ~$23/month if left running |
| Persistent Disk | 30GB | Free tier covers this |
| Outbound Network | 5GB/month | Model downloads count |

### Key Warnings
- ⚠️ **e2-micro (1GB RAM) is NOT enough** for any Ollama model
- ⚠️ **Minimum recommended**: e2-medium (2 vCPU, 4GB RAM) for `qwen2.5:1.5b`
- ⚠️ **Stop your VM when not in use** to avoid charges
- ⚠️ **Monitor usage** in Google Cloud Console → Billing
- ⚠️ **$300 free credits expire after 90 days**

### Cost Estimate
- **e2-medium VM**: ~$0.0316/hour (~$23/month if running 24/7)
- **Model download**: ~1-2GB (counts against network egress)
- **Storage**: 30GB persistent disk is free

**Total for occasional use**: **$0-5/month** if you stop the VM when done.

---

## Recommended Models

For a **4GB RAM VM** (e2-medium):

| **Model** | **Size** | **VRAM Required** | **Notes** |
|-----------|----------|-------------------|-----------|
| `qwen2.5:1.5b` | ~2.5GB | 4GB | **Recommended** - Good balance |
| `llama3.2:1b` | ~1.5GB | 4GB | Fast, good for chat |
| `gemma:2b` | ~2.5GB | 4GB | Google's model |
| `phi3:3.8b` | ~2.5GB | 4GB | Microsoft's model |

> **⚠️ WARNING**: Larger models (7B+) will **fail or be extremely slow** on 4GB RAM.

---

## Storage Behavior

### /tmp Persistence on Google Cloud VMs

| **Action** | **/tmp Contents** | **Ollama Models** | **Hermes Config** | **Reinstall Needed?** |
|------------|-------------------|-------------------|-------------------|----------------------|
| VM Reboot | **Survives** | Survives | Survives | ❌ No |
| VM Stop/Start | **Survives** | Survives | Survives | ❌ No |
| VM Deletion | **Lost** | Lost | Lost | ✅ Yes |
| VM Recreation | **Lost** | Lost | Lost | ✅ Yes |

> **Note**: `/tmp` is on the persistent disk by default, but some Linux distributions may clear it on reboot. If models disappear, re-run `ollama pull qwen2.5:1.5b`.

---

## Directory Structure

```
ollama-cloud-setup/
├── README.md               # This file - Overview and quick start
├── docs/
│   ├── ANDROID_GUIDE.md    # ✅ NEW: Complete Android/Termux guide
│   ├── ARCHITECTURE.md     # Storage limits and workflow
│   ├── SETUP_GUIDE.md      # Google Cloud Shell setup (legacy)
│   └── TROUBLESHOOTING.md  # Common issues and fixes
└── scripts/
    ├── start.sh            # Start Ollama + pull model
    └── cleanup.sh          # Clear cache to prevent ENOSPC
```

---

## Scripts

| **Script** | **Purpose** |
|------------|-------------|
| `scripts/start.sh` | Start Ollama, set `OLLAMA_MODELS=/tmp/ollama_models`, pull `qwen2.5:1.5b` |
| `scripts/cleanup.sh` | Clear `~/.cache`, `~/.npm`, and `/tmp` (except models) |

---

## Prerequisites

- **Android Phone** with Termux (from [F-Droid](https://f-droid.org))
- **Google Cloud Account** ([console.cloud.google.com](https://console.cloud.google.com))
- **Billing enabled** (required for free tier)
- **Basic Linux knowledge** (or willingness to copy-paste commands)

---

## Common Issues?

See **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** for fixes to:
- `ENOSPC` (disk full) errors
- Ollama server not running
- Model fails to load (out of memory)
- Hermes can't connect to Ollama
- Context window too small
- SSH connection issues

---

## Security Notes

1. **⚠️ SSH Keys**: Never share your private key (`~/.ssh/id_ed25519`)
2. **⚠️ VM Exposure**: Your VM's IP is public. Restrict SSH access in firewall rules
3. **⚠️ Root Access**: Disable root SSH login for better security
4. **⚠️ Hermes Gateway**: If using messaging (Telegram/Discord), be aware of privacy implications

---

## Quick Reference Commands

```bash
# Connect to VM from Termux
ssh your-username@EXTERNAL_IP

# Start Ollama and pull model
ollama serve & && ollama pull qwen2.5:1.5b

# Configure Hermes
hermes setup  # Select: Custom endpoint → http://127.0.0.1:11434/v1

# Start Hermes chat
hermes

# Check Ollama status
curl http://localhost:11434/v1/models

# Clean up disk space
rm -rf ~/.cache/*
find /tmp -mindepth 1 -maxdepth 1 ! -name "ollama_models" -exec rm -rf {} + 2>/dev/null || true
```

---

## Next Steps

1. **[Read the Full Android Guide](docs/ANDROID_GUIDE.md)** for detailed instructions
2. Try different models (`llama3.2:1b`, `gemma:2b`)
3. Set up Hermes Gateway for Telegram/Discord:
   ```bash
   hermes gateway setup
   ```
4. Experiment with agentic tasks (file analysis, automation)

---

## License

MIT License – Feel free to use, modify, and distribute.

---

## Contributing

Found an issue or have improvements? Open a PR or issue on GitHub.

---

*Last updated: September 2026 | Guide version: 2.0*
