# Hermes Agent + Ollama on Google Cloud: Android User Guide

> **A complete, beginner-friendly guide for Android users to run Hermes Agent with local Ollama models on Google Cloud VMs using Termux.**

---

## Overview

This guide explains how to set up **Hermes Agent** (an AI agent framework) with **Ollama** (local LLM inference) on a **Google Cloud VM**, accessible from your **Android phone** via **Termux**. The setup uses **free-tier resources** where possible and prioritizes temporary storage in `/tmp` to avoid permanent clutter.

### What You Will Build

```
Android Phone
    ↓ (Termux SSH)
Google Cloud VM
    ↓ (Install)
Hermes Agent + Ollama
    ↓ (Local Model)
Ollama Model (e.g., qwen2.5:1.5b)
```

### Architecture Explained

| **Component**          | **Role**                                                                                     | **Location**          |
|------------------------|---------------------------------------------------------------------------------------------|-----------------------|
| **Android Phone**      | Your device running Termux for SSH access                                                  | Local                 |
| **Termux**            | Android terminal emulator with SSH client                                                  | Android               |
| **Google Cloud VM**   | Virtual machine running Ubuntu/Debian (free-tier eligible)                                  | Cloud                 |
| **Hermes Agent**      | AI agent framework that connects to Ollama for inference                                   | VM (`~/.hermes`)      |
| **Ollama**            | Local LLM inference server                                                                   | VM (`~/.local/bin`)   |
| **Ollama Models**     | Downloaded models (stored in `/tmp/ollama_models` for temporary use)                       | VM (`/tmp`)           |

---

## Requirements

### For Your Android Phone
- **Termux** (from [F-Droid](https://f-droid.org/en/packages/com.termux/) for best compatibility)
- **Stable internet connection** (SSH and model downloads require bandwidth)
- **Basic Linux command knowledge** (we provide all commands to copy-paste)

### For Google Cloud
- **Google Cloud account** ([console.cloud.google.com](https://console.cloud.google.com))
- **Free-tier eligibility** (new accounts get $300 credit + always-free resources)
- **Billing enabled** (required to use free-tier, but you won't be charged if you stay within limits)

---

## Free Tier and Billing Considerations

> **⚠️ IMPORTANT: Google Cloud is NOT permanently free.**

### Free Tier Limits (as of 2026)

| **Resource**               | **Free Tier**                          | **What Happens If Exceeded**          |
|---------------------------|----------------------------------------|--------------------------------------|
| **Compute Engine**        | 1 x e2-micro (2 vCPU, 1GB RAM) / month | **You will be billed** at standard rates |
| **Persistent Disk**       | 30GB standard HDD                      | **You will be billed** for extra space |
| **Outbound Network**      | 5GB / month                            | **You will be billed** for extra traffic |
| **Inbound Network**       | Always free                            | No charge                              |

### Key Warnings
- **⚠️ Billing is enabled by default** when you create a project. You MUST monitor usage.
- **⚠️ Free credits ($300 for new accounts) expire after 90 days.** After that, you pay for all usage.
- **⚠️ The e2-micro instance (1GB RAM) is NOT enough for most Ollama models.** You need at least **4GB RAM** for `qwen2.5:1.5b`.
- **⚠️ CPU-only inference is SLOW.** Models will respond slowly without a GPU.
- **⚠️ Stop your VM when not in use** to avoid unnecessary charges.

### Recommended VM for Free Testing
- **Machine Type**: `e2-small` (2 vCPU, 2GB RAM) - **Not enough for models**
- **Machine Type**: `e2-medium` (2 vCPU, **4GB RAM**) - **Minimum for `qwen2.5:1.5b`**
- **OS**: Ubuntu 22.04 LTS or Debian 11
- **Disk**: 30GB persistent disk (free tier covers this)
- **Region**: `us-central1` (Iowa) or `us-west1` (Oregon) - often have free-tier availability

> **⚠️ Cost Estimate for e2-medium**: ~$0.0316/hour (~$23/month if left running 24/7). **Stop your VM when done!**

---

## Step 1: Set Up Google Cloud VM

### 1.1 Create a New Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click the project dropdown (top-left) → **New Project**
3. Name it `hermes-ollama` (or similar)
4. Click **Create**

### 1.2 Enable Billing (Required for Free Tier)

1. In the Cloud Console, go to **Billing** → **Manage billing accounts**
2. If you don't have a billing account, create one (you'll need a credit card)
3. Link your billing account to the `hermes-ollama` project
4. **Set a budget alert**: Billing → Budgets → Create Budget (set to $10 to get notified)

### 1.3 Create a Compute Engine VM

1. Navigate to **Compute Engine** → **VM Instances**
2. Click **Create Instance**
3. Configure as follows:

| **Setting**               | **Value**                          |
|--------------------------|------------------------------------|
| Name                     | `hermes-vm`                        |
| Region                   | `us-central1` (or nearest to you)  |
| Zone                     | `us-central1-a`                    |
| Machine Type             | `e2-medium` (2 vCPU, 4GB RAM)       |
| Boot Disk                | Ubuntu 22.04 LTS, 30GB              |
| Firewall                 | Allow HTTP/HTTPS traffic (checked) |

4. Click **Create**

### 1.4 Connect to VM via Browser SSH

1. In **VM Instances**, find `hermes-vm`
2. Click **SSH** button (opens a browser-based terminal)
3. Accept the connection (first time only)

---

## Step 2: Prepare the VM

### 2.1 Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### 2.2 Install Required Dependencies

```bash
# Install zstd for Ollama model compression
sudo apt install -y zstd curl git

# Install Python 3.11+ (required for Hermes)
sudo apt install -y python3 python3-pip python3-venv

# Verify Python version
python3 --version  # Should be 3.11 or higher
```

### 2.3 Set Up /tmp for Model Storage

```bash
# Create directory for models in /tmp
export OLLAMA_MODELS=/tmp/ollama_models
mkdir -p "$OLLAMA_MODELS"

# Verify /tmp has enough space
df -h /tmp
```

> **Note**: `/tmp` on Google Cloud VMs is on the **persistent disk** by default, so it survives reboots but NOT VM deletion. However, some system processes may clear `/tmp` on reboot. We'll document the reinstallation process later.

---

## Step 3: Install Termux on Android

### 3.1 Install Termux

1. **Do NOT install from Google Play Store** (outdated version)
2. Install from **F-Droid**:
   - Open [F-Droid website](https://f-droid.org) on your phone
   - Search for **Termux**
   - Download and install the APK

### 3.2 Set Up Termux

1. Open Termux
2. Update packages:
   ```bash
   pkg update && pkg upgrade -y
   ```
3. Install OpenSSH:
   ```bash
   pkg install openssh -y
   ```

---

## Step 4: Connect from Android to Google Cloud VM

### 4.1 Get Your VM's External IP

1. In Google Cloud Console → **VM Instances**
2. Find the **External IP** of `hermes-vm` (e.g., `34.123.45.67`)

### 4.2 Add SSH Key to VM

**Option A: Use Google Cloud's built-in SSH (Recommended)**
1. In Termux, run:
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```
   (Press Enter for all prompts to accept defaults)

2. Display your public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

3. Copy the entire output (starts with `ssh-ed25519`)

4. In Google Cloud Console:
   - Go to **Compute Engine** → **Metadata**
   - Click **SSH Keys** tab
   - Click **Add SSH Key**
   - Paste your public key
   - Click **Save**

**Option B: Use gcloud CLI (if you have it installed)**
```bash
gcloud compute ssh hermes-vm --zone us-central1-a
```

### 4.3 Connect via Termux

In Termux, run:
```bash
ssh your-google-cloud-username@EXTERNAL_IP
```

- Replace `your-google-cloud-username` with your Google Cloud username (usually your email prefix)
- Replace `EXTERNAL_IP` with your VM's external IP
- Type `yes` when prompted to verify the host
- Enter your SSH passphrase (if you set one)

> **Tip**: To avoid typing the IP every time, create an alias in Termux:
> ```bash
> echo "alias hermes-connect='ssh your-username@EXTERNAL_IP'" >> ~/.bashrc
> source ~/.bashrc
> ```
> Then just run `hermes-connect`

---

## Step 5: Install Ollama

### 5.1 Install Ollama on the VM

```bash
# Download and install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Add Ollama to PATH
export PATH="$HOME/.local/bin:$PATH"

# Verify installation
ollama --version
```

### 5.2 Configure Model Storage

```bash
# Set OLLAMA_MODELS to /tmp/ollama_models
export OLLAMA_MODELS=/tmp/ollama_models
mkdir -p "$OLLAMA_MODELS"

# Make it permanent (add to ~/.bashrc)
echo "export OLLAMA_MODELS=/tmp/ollama_models" >> ~/.bashrc
source ~/.bashrc
```

### 5.3 Start Ollama Server

```bash
# Start Ollama in background
ollama serve &

# Wait 5 seconds for server to initialize
sleep 5

# Verify it's running
curl http://localhost:11434/v1/models
```

Expected output:
```json
{"models": []}
```

---

## Step 6: Download an Ollama Model

### 6.1 Choose a Lightweight Model

For a **4GB RAM VM**, use one of these:

| **Model**            | **Size**  | **VRAM Required** | **Notes**                          |
|----------------------|-----------|-------------------|------------------------------------|
| `qwen2.5:1.5b`       | ~2.5GB    | 4GB               | Good balance of speed and quality |
| `llama3.2:1b`        | ~1.5GB    | 4GB               | Fast, good for chat               |
| `gemma:2b`           | ~2.5GB    | 4GB               | Google's model                     |
| `phi3:3.8b`          | ~2.5GB    | 4GB               | Microsoft's model                 |

> **⚠️ WARNING**: Larger models (7B+) will **fail or be extremely slow** on a 4GB RAM VM.

### 6.2 Pull the Model

```bash
# Pull qwen2.5:1.5b (recommended for 4GB RAM)
ollama pull qwen2.5:1.5b
```

This will take **5-20 minutes** depending on your internet speed. The model will be downloaded to `/tmp/ollama_models`.

### 6.3 Verify Model Download

```bash
# List downloaded models
ollama list
```

Expected output:
```
NAME              ID               SIZE      MODIFIED
qwen2.5:1.5b      abc123...        2.5 GB    2 minutes ago
```

### 6.4 Test the Model

```bash
# Run a quick test
ollama run qwen2.5:1.5b "Hello, are you working?"
```

Expected: The model should respond with a greeting.

> **⚠️ Note**: The first run will be slow as the model loads into memory.

---

## Step 7: Install Hermes Agent

### 7.1 Install Hermes Agent

```bash
# Download and run the official installer
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# Reload your shell
exec bash

# Verify installation
hermes --version
```

### 7.2 Configure Hermes to Use Ollama

Hermes has a built-in setup wizard. Run:

```bash
hermes setup
```

Follow these steps in the wizard:

1. **Setup Type**: Choose `Quick setup` (recommended)
2. **Provider**: Select `More providers...`
3. **Custom Endpoint**: Select `Custom endpoint (enter URL manually)`
4. **API Base URL**: Enter `http://127.0.0.1:11434/v1`
5. **API Key**: Leave **blank** (press Enter)
6. **Model Selection**: Hermes will auto-detect your Ollama models
   - Select `qwen2.5:1.5b` (or your downloaded model)
7. **Context Length**: Leave blank (auto-detect) or set to `32768`
8. **Messaging**: Choose `Skip` (we'll set this up later if needed)

### 7.3 Verify Hermes Configuration

```bash
# Check configured model
hermes model

# Check provider configuration
hermes config get provider
```

---

## Step 8: Test the Setup

### 8.1 Start Hermes Chat

```bash
hermes
```

This will start the **Terminal User Interface (TUI)**. Try sending a message like:

```
Hello, can you help me with something?
```

### 8.2 Test with a Simple Task

Try asking Hermes to:
- Write a short poem
- Explain a concept
- List files in a directory (`/tmp`)

### 8.3 Exit Hermes

Press `Ctrl+C` or type `/exit` to quit.

---

## Step 9: Restart / Temporary Storage Behavior

### Understanding VM States and /tmp Persistence

| **Action**               | **VM Status** | **/tmp Contents** | **Ollama Models** | **Hermes Config** | **What You Need to Do** |
|--------------------------|---------------|-------------------|-------------------|-------------------|------------------------|
| **Reboot VM**            | Restarts      | **Survives**      | Survives          | Survives          | Just reconnect via SSH |
| **Stop & Start VM**      | Stopped → Running | **Survives**      | Survives          | Survives          | Just reconnect via SSH |
| **VM Deletion**          | Deleted       | **Lost**          | Lost              | **Lost**          | Full reinstall needed |
| **VM Recreation**        | New VM        | **Lost**          | Lost              | Lost              | Full reinstall needed |

> **⚠️ Important Notes:**
> - `/tmp` is on the **persistent disk** by default on Google Cloud VMs, so it survives reboots and stop/start cycles.
> - However, **some Linux distributions clear `/tmp` on reboot** via `systemd-tmpfiles`. If your models disappear after reboot, see the reinstallation steps below.
> - **Hermes configuration** is stored in `~/.hermes/` (in your home directory), which is on the persistent disk.
> - **Ollama installation** is in `~/.local/bin/`, which is also persistent.

### 9.1 If Models Disappear After Reboot

If `/tmp/ollama_models` is cleared, run:

```bash
# Recreate the directory
mkdir -p /tmp/ollama_models

# Redownload the model
ollama pull qwen2.5:1.5b

# Restart Ollama server
pkill ollama
ollama serve &
```

### 9.2 If Ollama Server Isn't Running

```bash
# Check if Ollama is running
ps aux | grep ollama

# If not, start it
ollama serve &
```

### 9.3 Full Reinstallation (After VM Deletion)

If you delete and recreate the VM, you'll need to:

1. Reconnect via SSH (IP may have changed)
2. Re-run all installation steps:
   ```bash
   # Update and install dependencies
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y zstd curl git python3 python3-pip
   
   # Reinstall Ollama
   curl -fsSL https://ollama.com/install.sh | sh
   export PATH="$HOME/.local/bin:$PATH"
   
   # Reinstall Hermes
   curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
   exec bash
   
   # Reconfigure
   export OLLAMA_MODELS=/tmp/ollama_models
   mkdir -p "$OLLAMA_MODELS"
   ollama pull qwen2.5:1.5b
   ollama serve &
   hermes setup
   ```

---

## Step 10: Optimize for Android Use

### 10.1 Create a Startup Script

Create a script to start everything automatically:

```bash
# Create the script
cat > ~/start-hermes.sh << 'EOF'
#!/bin/bash

# Start Ollama server
export OLLAMA_MODELS=/tmp/ollama_models
mkdir -p "$OLLAMA_MODELS"

# Check if model exists, if not pull it
if [ ! -d "$OLLAMA_MODELS/qwen2.5:1.5b" ]; then
    echo "Model not found. Pulling qwen2.5:1.5b..."
    ollama pull qwen2.5:1.5b
fi

# Start Ollama in background
pkill ollama 2>/dev/null || true
sleep 2
ollama serve &
sleep 5

# Start Hermes
exec hermes
EOF

# Make it executable
chmod +x ~/start-hermes.sh
```

### 10.2 Run the Script

```bash
./start-hermes.sh
```

This will:
1. Ensure the model directory exists
2. Download the model if missing
3. Start Ollama
4. Launch Hermes

---

## Troubleshooting

### Common Issues and Fixes

#### 1. **ENOSPC (No Space Left) Error**

**Symptoms**: `Error: ENOSPC: no space left on device`

**Causes**:
- `/tmp` is full (unlikely on 30GB disk)
- `/home` is full (more likely)

**Solutions**:
```bash
# Check disk usage
df -h

# Clear ~/.cache
rm -rf ~/.cache/*

# Clear /tmp (except our models)
find /tmp -mindepth 1 -maxdepth 1 ! -name "ollama_models" -exec rm -rf {} + 2>/dev/null || true
```

#### 2. **Ollama Server Not Running**

**Symptoms**: `Connection refused` when testing Ollama API

**Fix**:
```bash
# Kill any existing Ollama process
pkill ollama

# Start fresh
ollama serve &
sleep 5
curl http://localhost:11434/v1/models
```

#### 3. **Model Fails to Load (Out of Memory)**

**Symptoms**: Ollama crashes or model fails to load

**Causes**: Model is too large for your VM's RAM

**Solutions**:
- Use a smaller model (e.g., `qwen2.5:1.5b` instead of `llama3.2:3b`)
- Upgrade your VM to `e2-standard-4` (8GB RAM) for larger models
- Close other applications to free memory

#### 4. **Hermes Can't Connect to Ollama**

**Symptoms**: Hermes errors about connection to `http://127.0.0.1:11434/v1`

**Fix**:
```bash
# Verify Ollama is running
curl http://localhost:11434/v1/models

# If not, restart Ollama
pkill ollama
ollama serve &

# Reconfigure Hermes
hermes setup
# Select "Custom endpoint" and enter http://127.0.0.1:11434/v1
```

#### 5. **Context Window Too Small**

**Symptoms**: Hermes behaves erratically, forgets context quickly

**Cause**: Ollama's default context window is too small for Hermes (needs 64K+ tokens)

**Fix**:
```bash
# Create a Modelfile for your model
cat > /tmp/Modelfile << 'EOF'
FROM qwen2.5:1.5b
PARAMETER num_ctx 65536
EOF

# Rebuild the model with new context
ollama create qwen2.5-64k -f /tmp/Modelfile

# Use the new model in Hermes
hermes model
# Select qwen2.5-64k
```

#### 6. **SSH Connection Refused**

**Symptoms**: `Connection refused` when trying to SSH from Termux

**Fix**:
1. Check your VM is running in Google Cloud Console
2. Verify the external IP hasn't changed
3. Check firewall rules:
   ```bash
   # In Google Cloud Console, go to VPC Network → Firewall
   # Ensure there's a rule allowing TCP:22 from 0.0.0.0/0
   ```
4. Restart the SSH service on VM:
   ```bash
   sudo service ssh restart
   ```

#### 7. **Termux SSH Permissions**

**Symptoms**: Permission denied when trying to SSH

**Fix**:
```bash
# In Termux
chmod 600 ~/.ssh/id_ed25519
chmod 700 ~/.ssh
```

---

## Security Notes

### ⚠️ Important Security Considerations

1. **SSH Keys**: Your private key (`~/.ssh/id_ed25519`) is **sensitive**. Never share it.
2. **VM Exposure**: Your VM's external IP is public. **Do NOT** run Hermes on a public IP without authentication.
3. **Firewall**: Google Cloud's default firewall allows SSH (port 22) from anywhere. Consider restricting to your IP.
4. **Hermes Gateway**: If you set up messaging (Telegram, Discord), be aware that:
   - Conversations may be visible to the platform
   - Anyone with access to the bot can interact with your agent
5. **Model Data**: All inference happens on your VM. No data leaves unless you configure external integrations.

### Recommended Security Steps

1. **Restrict SSH Access**:
   ```bash
   # In Google Cloud Console → VPC Network → Firewall
   # Edit the default-allow-ssh rule
   # Change source IP ranges from 0.0.0.0/0 to your specific IP
   ```

2. **Use a Non-Root User**:
   ```bash
   # On your VM
   sudo adduser hermes-user
   sudo usermod -aG sudo hermes-user
   # Then SSH as hermes-user instead of root
   ```

3. **Disable Root SSH**:
   ```bash
   sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
   sudo service ssh restart
   ```

---

## Quick Start Commands

For quick reference, here are the essential commands:

```bash
# Connect to VM from Termux
ssh your-username@EXTERNAL_IP

# Start everything
./start-hermes.sh

# Check Ollama status
curl http://localhost:11434/v1/models

# Reinstall after VM recreation
sudo apt update && sudo apt upgrade -y && \
sudo apt install -y zstd curl git python3 python3-pip && \
curl -fsSL https://ollama.com/install.sh | sh && \
exec bash && \
export OLLAMA_MODELS=/tmp/ollama_models && \
mkdir -p "$OLLAMA_MODELS" && \
ollama pull qwen2.5:1.5b && \
ollama serve & && \
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash && \
exec bash && \
hermes setup

# Clean up disk space
rm -rf ~/.cache/* && \
find /tmp -mindepth 1 -maxdepth 1 ! -name "ollama_models" -exec rm -rf {} + 2>/dev/null || true
```

---

## Conclusion

You now have a **fully functional Hermes Agent + Ollama setup** running on Google Cloud, accessible from your Android phone via Termux. This setup:

✅ Uses **local models** (no API costs)
✅ Runs on **Google Cloud free-tier eligible resources**
✅ Is accessible from **anywhere via SSH**
✅ Stores models in **/tmp** for easy cleanup
✅ Is **beginner-friendly** with copy-paste commands

### Next Steps

1. **Experiment with different models** (try `llama3.2:1b` or `gemma:2b`)
2. **Set up Hermes Gateway** to connect to Telegram/Discord:
   ```bash
   hermes gateway setup
   ```
3. **Try agentic tasks**: Ask Hermes to write code, analyze files, or automate tasks
4. **Monitor your Google Cloud usage** to avoid unexpected charges

### Remember
- **Stop your VM when not in use** to save costs
- **/tmp models may need reinstallation** after some reboots
- **Stay within free-tier limits** to avoid charges
- **This is a temporary setup** - for permanent use, consider persistent storage

---

## Additional Resources

- [Ollama Documentation](https://docs.ollama.com)
- [Hermes Agent GitHub](https://github.com/NousResearch/hermes-agent)
- [Google Cloud Free Tier](https://cloud.google.com/free)
- [Termux Documentation](https://termux.com/docs.html)

---

*Last updated: September 2026 | Guide version: 1.0*
