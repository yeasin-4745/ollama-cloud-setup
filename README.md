# Hermes Agent + Ollama on Google Cloud

[![Ollama](https://img.shields.io/badge/Ollama-v0.3.0-blue)](https://ollama.com)
[![Hermes Agent](https://img.shields.io/badge/Hermes_Agent-v2.0-orange)](https://github.com/NousResearch/hermes-agent)
[![Google Cloud](https://img.shields.io/badge/Google_Cloud-Compute_Engine-4285F4)](https://cloud.google.com/compute)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**Run Hermes Agent with local Ollama models on Google Cloud VMs with a single command.**

---

## Quick Start

The fastest way to get started:

### 1. Create a Google Cloud VM
- Go to [Google Cloud Console](https://console.cloud.google.com)
- Create a VM with **Ubuntu 22.04**, **e2-medium** (2 vCPU, 4GB RAM), 30GB disk
- **Enable billing** (required for free tier)

### 2. Open the VM Terminal
- In Google Cloud Console, go to **Compute Engine** → **VM Instances**
- Click **SSH** button next to your VM (opens browser-based terminal)

### 3. Run the One-Command Installer

```bash
# Option 1: Clone repo and run (RECOMMENDED - safer)
git clone https://github.com/yeasin-4745/ollama-cloud-setup.git
cd ollama-cloud-setup
bash install.sh
```

```bash
# Option 2: Direct curl (review script first at the link below)
curl -fsSL https://raw.githubusercontent.com/yeasin-4745/ollama-cloud-setup/main/install.sh | bash
```

> **⚠️ Security Note**: Always review scripts before piping to bash. View the script here: [install.sh](https://github.com/yeasin-4745/ollama-cloud-setup/blob/main/install.sh)

### 4. Wait for Installation
- The script will:
  1. Check system requirements
  2. Install dependencies
  3. Install Ollama
  4. Configure model storage in `/tmp`
  5. Download `qwen2.5:1.5b` (lightweight model for 4GB RAM)
  6. Start Ollama server
  7. Install Hermes Agent
  8. Configure Hermes to use local Ollama
  9. Verify everything works

### 5. Start Using Hermes

```bash
# Start chatting with Hermes
hermes

# Test Ollama API
curl http://localhost:11434/v1/models

# List downloaded models
ollama list
```

---

## Architecture

```
Google Cloud VM
    │
    ├── Hermes Agent (AI agent framework)
    │       ↓
    └── Ollama (Local LLM inference server)
            │
            └── Local Ollama Model (e.g., qwen2.5:1.5b in /tmp/ollama_models)
```

### Optional Android Workflow

```
Android Phone
    │
    └── Termux (OPTIONAL - for SSH access)
            │
            ↓ (SSH)
    Google Cloud VM
        │
        ├── Hermes Agent
        └── Ollama → Local Model
```

> **Note**: Termux is **OPTIONAL**. The primary method uses Google Cloud's built-in SSH terminal.

---

## Detailed Setup

For users who want to understand each step, see:
- **[Complete Android/Termux Guide](docs/ANDROID_GUIDE.md)** - Detailed instructions for Android users
- **[Setup Guide](docs/SETUP_GUIDE.md)** - Manual setup steps

---

## Free Tier and Billing

> **⚠️ IMPORTANT: Google Cloud is NOT permanently free.**

### Free Tier Limits (as of 2026)

| **Resource** | **Free Tier** | **Notes** |
|--------------|---------------|-----------|
| Compute Engine | 1 x e2-micro/month | **Not enough for Ollama** |
| **e2-medium** | ~$0.0316/hour | **Recommended minimum** |
| Persistent Disk | 30GB | Free tier covers this |
| Outbound Network | 5GB/month | Model downloads count |

### Key Warnings
- ⚠️ **e2-micro (1GB RAM) is NOT enough** for any Ollama model
- ⚠️ **Minimum**: e2-medium (2 vCPU, **4GB RAM**) for `qwen2.5:1.5b`
- ⚠️ **Stop your VM when not in use** to avoid charges (~$23/month if left running 24/7)
- ⚠️ **Monitor usage** in Google Cloud Console → Billing
- ⚠️ **$300 free credits expire after 90 days**

### Cost Estimate
- **e2-medium VM**: ~$0.0316/hour (~$23/month if running continuously)
- **Model download**: ~1-2GB (counts against network egress)
- **Storage**: 30GB persistent disk is free

**Total for occasional use**: **$0-5/month** if you stop the VM when done.

---

## Temporary Storage Behavior

This setup uses `/tmp/ollama_models` for model storage to avoid permanent clutter.

| **Action** | **/tmp Contents** | **Ollama Models** | **Hermes Config** | **Reinstall Needed?** |
|------------|-------------------|-------------------|-------------------|----------------------|
| **VM Reboot** | **Survives** | Survives | Survives | ❌ No |
| **VM Stop/Start** | **Survives** | Survives | Survives | ❌ No |
| **VM Deletion** | **Lost** | Lost | Lost | ✅ Yes |
| **VM Recreation** | **Lost** | Lost | Lost | ✅ Yes |

> **Note**: `/tmp` is on the persistent disk by default on Google Cloud VMs. However, some Linux distributions may clear `/tmp` on reboot. If models disappear, simply re-run `bash install.sh`.

---

## Customization

### Change the Model

The installer downloads `qwen2.5:1.5b` by default. To use a different model:

```bash
# Option 1: Set environment variable before running
MODEL_NAME="llama3.2:1b" bash install.sh

# Option 2: Set custom model storage location
OLLAMA_MODELS="/tmp/my_custom_models" bash install.sh
```

### Recommended Models for 4GB RAM

| **Model** | **Size** | **Notes** |
|-----------|----------|-----------|
| `qwen2.5:1.5b` | ~2.5GB | **Default - Good balance** |
| `llama3.2:1b` | ~1.5GB | Fast, good for chat |
| `gemma:2b` | ~2.5GB | Google's model |
| `phi3:3.8b` | ~2.5GB | Microsoft's model |

> **⚠️ WARNING**: Larger models (7B+) will **fail or be extremely slow** on 4GB RAM.

---

## Uninstall

To remove everything:

```bash
# Clone repo if not already done
git clone https://github.com/yeasin-4745/ollama-cloud-setup.git
cd ollama-cloud-setup

# Run uninstaller
bash uninstall.sh
```

This will remove:
- Ollama binary and all models
- Hermes Agent and configuration
- `/tmp/ollama_models` directory

It will **NOT** remove:
- System dependencies (curl, git, python3, etc.)
- Your home directory or personal files

---

## Repository Structure

```
ollama-cloud-setup/
├── README.md              # This file - Quick start and overview
├── LICENSE                # MIT License
├── install.sh             # One-command installer
├── uninstall.sh           # Cleanup script
└── docs/
    ├── ANDROID_GUIDE.md   # Complete Android/Termux guide
    ├── ARCHITECTURE.md    # Storage limits and workflow
    ├── SETUP_GUIDE.md     # Manual setup steps
    └── TROUBLESHOOTING.md  # Common issues and fixes
```

---

## Troubleshooting

### Common Issues

| **Issue** | **Solution** |
|-----------|--------------|
| `ENOSPC` (No space) | Run `bash uninstall.sh` and try again |
| Ollama server not running | Run `ollama serve &` |
| Model fails to load | Use a smaller model (e.g., `llama3.2:1b`) |
| Hermes can't connect | Verify Ollama API: `curl http://localhost:11434/v1/models` |
| SSH connection refused | Check VM is running and firewall allows SSH |

### Full Troubleshooting Guide

See **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** for detailed fixes.

---

## Security Notes

1. **⚠️ Script Review**: Always review scripts before running them with `curl | bash`
2. **⚠️ SSH Keys**: Never share your private key
3. **⚠️ VM Exposure**: Your VM's IP is public. Restrict SSH access in firewall rules
4. **⚠️ Root Access**: Avoid running as root. Use a non-root user
5. **⚠️ Ollama API**: By default, Ollama only listens on `localhost`. Do NOT expose port 11434 publicly without authentication

---

## Quick Reference Commands

```bash
# Install everything
bash install.sh

# Start Hermes chat
hermes

# Test Ollama API
curl http://localhost:11434/v1/models

# List models
ollama list

# Pull a different model
ollama pull llama3.2:1b

# Stop Ollama
pkill ollama

# Restart Ollama
ollama serve &

# Reinstall after VM restart
bash install.sh

# Clean up
bash uninstall.sh
```

---

## Next Steps

1. **Try different models** (`llama3.2:1b`, `gemma:2b`, `phi3:3.8b`)
2. **Set up Hermes Gateway** for Telegram/Discord:
   ```bash
   hermes gateway setup
   ```
3. **Experiment with agentic tasks** (file analysis, automation)
4. **Monitor your Google Cloud usage** to avoid unexpected charges

---

## License

MIT License – Feel free to use, modify, and distribute.

---

## Contributing

Found an issue or have improvements? Open a PR or issue on GitHub.

---

*Last updated: September 2026 | Version: 3.0*
