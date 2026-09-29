# Ollama on Google Cloud Shell

[![Ollama](https://img.shields.io/badge/Ollama-v0.3.0-blue)](https://ollama.com)
[![Cloud Shell](https://img.shields.io/badge/Google_Cloud-Shell-orange)](https://cloud.google.com/shell)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**A modular, production-ready guide for running Ollama models in Google Cloud Shell.**

---

## Overview

This project provides a **structured, beginner-friendly** setup for running **Ollama** (lightweight LLM inference) in **Google Cloud Shell**, with:
- **Optimized storage** (using `/tmp` to bypass 5GB `/home` limits).
- **Automated scripts** for setup, cleanup, and model pulling.
- **Detailed documentation** in English and Bengali.
- **Troubleshooting** for common Cloud Shell issues.

---

## Architecture

| **Component**       | **Path**            | **Size**       | **Persistence**       | **Use Case**                |
|---------------------|---------------------|----------------|-----------------------|-----------------------------|
| `/home`             | Persistent          | 5GB            | Survives sessions     | Configs, scripts            |
| `/tmp`              | Ephemeral           | 100GB+         | Cleared on inactivity | Models, temp files          |

> **Why `/tmp`?** Google Cloud Shell’s `/home` is limited to **5GB**, while `/tmp` offers **100GB+**—ideal for storing large models like `qwen2.5:1.5b`.

---

## Quick Start

1. **Clone or copy this repo** into your Cloud Shell home directory.
2. **Make scripts executable**:
   ```bash
   chmod +x scripts/*.sh
   ```
3. **Start Ollama and pull the model**:
   ```bash
   ./scripts/start.sh
   ```
4. **Test the API**:
   ```bash
   curl http://localhost:11434/v1/models
   ```

---

## Directory Structure

```
cloudshell-hermes-ollama-guide/
├── README.md               # Project overview and quick start
├── .gitignore              # Git ignore rules
├── scripts/
│   ├── start.sh            # Start Ollama + pull model (qwen2.5:1.5b)
│   └── cleanup.sh          # Clear cache to prevent ENOSPC errors
└── docs/
    ├── ARCHITECTURE.md     # Storage limits and workflow
    ├── SETUP_GUIDE.md      # Step-by-step setup (English + বাংলা)
    └── TROUBLESHOOTING.md  # Fixes for ENOSPC, systemd, OOM, etc.
```

---

## Documentation

| **File**               | **Description**                                      |
|------------------------|------------------------------------------------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Storage limits, `/home` vs `/tmp`, and workflow.     |
| [SETUP_GUIDE.md](docs/SETUP_GUIDE.md)   | Beginner-friendly setup (English + বাংলা).          |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Solutions for ENOSPC, systemd, OOM, and more.       |

---

## Scripts

| **Script**          | **Purpose**                                      |
|---------------------|--------------------------------------------------|
| `scripts/start.sh`  | Start Ollama, set `OLLAMA_MODELS=/tmp/ollama_models`, pull `qwen2.5:1.5b`. |
| `scripts/cleanup.sh`| Clear `~/.cache`, `~/.npm`, and `/tmp` (except models). |

---

## Prerequisites

- **Google Cloud Shell** ([console.cloud.google.com](https://console.cloud.google.com))
- **Basic Linux knowledge** (or follow the [Setup Guide](docs/SETUP_GUIDE.md))
- **Dependencies**: `curl`, `zstd` (installed via `scripts/start.sh`)

---

## Key Features

✅ **Modular Design** – Scripts and docs are decoupled for easy maintenance.
✅ **Space-Optimized** – Uses `/tmp` to avoid `ENOSPC` errors.
✅ **Beginner-Friendly** – Guides in **English + বাংলা**.
✅ **Production-Ready** – Includes cleanup, troubleshooting, and best practices.

---

## Common Issues?

See **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** for fixes to:
- `ENOSPC` (disk full) errors
- `systemd not running` warnings
- Process killed (OOM or timeout)
- Port conflicts

---

## License

MIT License – Feel free to use, modify, and distribute.
