# Setup Guide

## Beginner-Friendly Step-by-Step Instructions

This guide covers installing **Hermes Agent**, **Ollama**, and configuring the endpoint for Google Cloud Shell.

---

## English Version

### Prerequisites
- A **Google Cloud Shell** session ([console.cloud.google.com](https://console.cloud.google.com))
- Basic familiarity with Linux commands

### Step 1: Install Dependencies

1. **Update packages**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install `zstd` (required for Ollama model compression)**:
   ```bash
   sudo apt install -y zstd
   ```

### Step 2: Install Ollama

1. **Download and install Ollama**:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ```

2. **Add Ollama to PATH**:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

3. **Verify installation**:
   ```bash
   ollama --version
   ```

### Step 3: Install Hermes Agent (Optional)

If you want to use **Hermes Agent** (a UI for Ollama):

1. **Install Node.js (v18+)**:
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

2. **Install Hermes Agent**:
   ```bash
   npm install -g hermes-agent
   ```

3. **Link Hermes to Ollama**:
   - Set the endpoint to `http://localhost:11434/v1` in Hermes Agent config.

### Step 4: Run the Setup

1. **Make scripts executable**:
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Start Ollama and pull the model**:
   ```bash
   ./scripts/start.sh
   ```

3. **Verify the model**:
   ```bash
   ollama list
   ```

---

## বাংলা সংস্করণ (Bangla Version)

### প্রিইকুইজিট
- একটি **Google Cloud Shell** সেশন ([console.cloud.google.com](https://console.cloud.google.com))
- লিনাক্স কমান্ডের মৌলিক ধারণা

### ধাপ ১: ডিপেন্ডেন্সি ইনস্টল করুন

1. **প্যাকেজ আপডেট করুন**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **`zstd` ইনস্টল করুন (Ollama মডেল কমপ্রেশনের জন্য দরকার)**:
   ```bash
   sudo apt install -y zstd
   ```

### ধাপ ২: Ollama ইনস্টল করুন

1. **Ollama ডাউনলোড এবং ইনস্টল করুন**:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ```

2. **PATH-এ Ollama যোগ করুন**:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

3. **ইনস্টলেশন ভেরিফাই করুন**:
   ```bash
   ollama --version
   ```

### ধাপ ৩: Hermes Agent ইনস্টল করুন (ঐচ্ছিক)

যদি আপনি **Hermes Agent** (Ollama-এর জন্য UI) ব্যবহার করতে চান:

1. **Node.js (v18+) ইনস্টল করুন**:
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

2. **Hermes Agent ইনস্টল করুন**:
   ```bash
   npm install -g hermes-agent
   ```

3. **Hermes কে Ollama-র সাথে লিঙ্ক করুন**:
   - Hermes Agent কনফিগারে এন্ডপয়েন্ট সেট করুন: `http://localhost:11434/v1`

### ধাপ ৪: সেটআপ চালু করুন

1. **স্ক্রিপ্টগুলিকে এক্সিকিউটেবল করুন**:
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Ollama চালু করুন এবং মডেল পুল করুন**:
   ```bash
   ./scripts/start.sh
   ```

3. **মডেল ভেরিফাই করুন**:
   ```bash
   ollama list
   ```

---

## Next Steps
- [Troubleshooting Common Issues](TROUBLESHOOTING.md)
- [Architecture Deep Dive](ARCHITECTURE.md)
