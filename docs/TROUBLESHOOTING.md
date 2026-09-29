# Troubleshooting Guide

## Common Issues and Solutions

### 1. **ENOSPC (No Space Left on Device) Error**

#### **Symptoms**
- `Error: ENOSPC: no space left on device` when pulling models.
- Ollama fails to download models or crashes during inference.

#### **Causes**
- `/home` directory is full (5GB limit).
- `/tmp` is cluttered with old files.

#### **Solutions**

##### **A. Store Models in `/tmp` (Recommended)**
Set `OLLAMA_MODELS` to `/tmp/ollama_models`:
```bash
export OLLAMA_MODELS=/tmp/ollama_models
mkdir -p "$OLLAMA_MODELS"
```

##### **B. Clean Up Cache and Temp Files**
Run the cleanup script:
```bash
./scripts/cleanup.sh
```

##### **C. Manually Free Space**
```bash
# Clear ~/.cache
rm -rf ~/.cache/*

# Clear NPM cache
npm cache clean --force

# Clear /tmp (except ollama_models)
find /tmp -mindepth 1 -maxdepth 1 ! -name "ollama_models" -exec rm -rf {} + 2>/dev/null || true
```

---

### 2. **Systemd Not Running Warning**

#### **Symptoms**
- Warning: `systemd is not running` when starting Ollama.
- Ollama server fails to start in the background.

#### **Causes**
- Google Cloud Shell does **not** use `systemd` (it uses a custom init system).

#### **Solutions**

##### **A. Run Ollama in Background Manually**
```bash
ollama serve &
```

##### **B. Use `nohup` to Prevent Process Termination**
```bash
nohup ollama serve > ollama.log 2>&1 &
```

##### **C. Verify Ollama is Running**
```bash
ps aux | grep ollama
```

---

### 3. **Process Killed (OOM or Session Timeout)**

#### **Symptoms**
- Ollama process is **killed** after a few minutes.
- Session terminates unexpectedly.

#### **Causes**
- **Out of Memory (OOM)**: Model requires more RAM than Cloud Shell provides (~2GB).
- **Session Timeout**: Google Cloud Shell times out after **30 minutes of inactivity**.

#### **Solutions**

##### **A. Use a Smaller Model**
Switch to a **lightweight model** (e.g., `qwen2.5:1.5b` instead of `llama3.2:3b`):
```bash
ollama pull qwen2.5:1.5b
```

##### **B. Reduce Model VRAM Usage**
Set `OLLAMA_MAX_LOADED_MODELS=1` to limit concurrent models:
```bash
export OLLAMA_MAX_LOADED_MODELS=1
```

##### **C. Keep Session Active**
Run a **loop to prevent timeout**:
```bash
while true; do sleep 60; done &
```

##### **D. Monitor Memory Usage**
```bash
free -h
```

---

### 4. **Port 11434 Already in Use**

#### **Symptoms**
- `Error: listen tcp 127.0.0.1:11434: bind: address already in use`

#### **Solutions**

##### **A. Kill Existing Ollama Process**
```bash
pkill ollama
```

##### **B. Change Ollama Port**
Set `OLLAMA_HOST` and `OLLAMA_PORT`:
```bash
export OLLAMA_HOST=0.0.0.0
export OLLAMA_PORT=11435
ollama serve
```

---

### 5. **Model Pull Fails or Stalls**

#### **Symptoms**
- `ollama pull` hangs or fails mid-download.
- Network errors (e.g., `404 Not Found`).

#### **Solutions**

##### **A. Retry with `--verbose`**
```bash
ollama pull qwen2.5:1.5b --verbose
```

##### **B. Check Network Connectivity**
```bash
curl -v https://ollama.com
```

##### **C. Use a Mirror (If Available)**
```bash
export OLLAMA_MODEL_URL=https://ollama-mirror.example.com
ollama pull qwen2.5:1.5b
```

---

## Debugging Commands

| **Command**                          | **Purpose**                                  |
|--------------------------------------|---------------------------------------------|
| `ollama --version`                   | Check Ollama version                        |
| `ollama list`                        | List downloaded models                      |
| `ps aux | grep ollama`               | Check if Ollama is running                  |
| `free -h`                            | Check memory usage                          |
| `df -h`                              | Check disk space                            |
| `tail -f /tmp/ollama.log`            | View Ollama logs (if running in background) |

---

## Still Stuck?
- Check the [Architecture Guide](ARCHITECTURE.md) for storage details.
- Re-run the [Setup Guide](SETUP_GUIDE.md) from scratch.
- Open an issue with:
  - Your **Cloud Shell environment** (Ubuntu version, RAM).
  - The **exact error message**.
  - Steps to **reproduce the issue**.
