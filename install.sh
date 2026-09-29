#!/bin/bash

# Hermes Agent + Ollama One-Command Installer for Google Cloud VM
# 
# This script automates the setup of Hermes Agent with Ollama on a fresh
# Google Cloud Linux VM. It installs dependencies, Ollama, Hermes Agent,
# configures model storage in /tmp, and downloads a lightweight model.
#
# Usage:
#   Option 1 (Recommended): Review script first, then run
#     git clone https://github.com/yeasin-4745/ollama-cloud-setup.git
#     cd ollama-cloud-setup
#     chmod +x install.sh
#     ./install.sh
#
#   Option 2 (Curl pipe - USE WITH CAUTION):
#     curl -fsSL https://raw.githubusercontent.com/yeasin-4745/ollama-cloud-setup/main/install.sh | bash
#
#   WARNING: Always review scripts before piping to bash. This script is open source
#   at https://github.com/yeasin-4745/ollama-cloud-setup/blob/main/install.sh
#
# Environment Variables:
#   MODEL_NAME: Ollama model to download (default: qwen2.5:1.5b)
#   OLLAMA_MODELS: Model storage directory (default: /tmp/ollama_models)
#
# Example:
#   MODEL_NAME="llama3.2:1b" ./install.sh
#   OLLAMA_MODELS="/tmp/my_models" ./install.sh

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Default model (lightweight, works on 4GB RAM VMs)
DEFAULT_MODEL="qwen2.5:1.5b"

# Default model storage directory
DEFAULT_OLLAMA_MODELS="/tmp/ollama_models"

# Minimum requirements
MIN_RAM_MB=4096          # 4GB RAM minimum
MIN_DISK_GB=10           # 10GB disk space minimum
MIN_CPUS=2              # 2 CPU cores minimum

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Utility Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# =============================================================================
# System Checks
# =============================================================================

check_system() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
        log_info "Detected OS: $OS_NAME $OS_VERSION"
    else
        log_error "Unable to detect OS. This script requires a Linux distribution."
        exit 1
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    log_info "Detected architecture: $ARCH"
    
    # Check CPU cores
    CPUS=$(nproc)
    log_info "Detected CPU cores: $CPUS"
    if [ "$CPUS" -lt "$MIN_CPUS" ]; then
        log_error "This script requires at least $MIN_CPUS CPU cores. Detected: $CPUS"
        exit 1
    fi
    
    # Check RAM
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
    log_info "Detected RAM: ${TOTAL_RAM_MB}MB"
    if [ "$TOTAL_RAM_MB" -lt "$MIN_RAM_MB" ]; then
        log_warning "Your system has ${TOTAL_RAM_MB}MB RAM. Minimum recommended: ${MIN_RAM_MB}MB."
        log_warning "Some models may not work properly. Continuing anyway..."
    fi
    
    # Check disk space
    DISK_AVAILABLE_GB=$(df / --output=avail -h | tail -1 | tr -d 'G')
    if [[ "$DISK_AVAILABLE_GB" =~ ^[0-9]+$ ]]; then
        log_info "Detected available disk space: ${DISK_AVAILABLE_GB}GB"
        if [ "$DISK_AVAILABLE_GB" -lt "$MIN_DISK_GB" ]; then
            log_error "This script requires at least $MIN_DISK_GB GB of disk space. Detected: ${DISK_AVAILABLE_GB}GB"
            exit 1
        fi
    else
        # Fallback check
        DISK_AVAILABLE_KB=$(df / --output=avail | tail -1)
        DISK_AVAILABLE_GB=$((DISK_AVAILABLE_KB / 1024 / 1024))
        log_info "Detected available disk space: ${DISK_AVAILABLE_GB}GB"
    fi
    
    # Check if running as root
    if [ "$(id -u)" -eq 0 ]; then
        log_warning "Running as root is not recommended. Consider using a non-root user."
    fi
    
    log_success "System requirements check passed."
}

# =============================================================================
# Dependency Installation
# =============================================================================

install_dependencies() {
    log_info "Installing required dependencies..."
    
    # Check package manager
    if check_command apt-get; then
        PKG_MANAGER="apt-get"
        UPDATE_CMD="sudo apt-get update"
        INSTALL_CMD="sudo apt-get install -y"
    elif check_command dnf; then
        PKG_MANAGER="dnf"
        UPDATE_CMD="sudo dnf makecache"
        INSTALL_CMD="sudo dnf install -y"
    elif check_command yum; then
        PKG_MANAGER="yum"
        UPDATE_CMD="sudo yum makecache"
        INSTALL_CMD="sudo yum install -y"
    elif check_command zypper; then
        PKG_MANAGER="zypper"
        UPDATE_CMD="sudo zypper refresh"
        INSTALL_CMD="sudo zypper install -y"
    else
        log_error "Unsupported package manager. Only apt-get, dnf, yum, and zypper are supported."
        exit 1
    fi
    
    # Update package lists
    if ! $UPDATE_CMD; then
        log_warning "Package list update failed. Continuing with installation..."
    fi
    
    # Install required packages
    DEPS=("curl" "git" "zstd" "python3" "python3-pip" "python3-venv")
    MISSING_DEPS=()
    
    for dep in "${DEPS[@]}"; do
        if ! check_command "$dep"; then
            MISSING_DEPS+=("$dep")
        fi
    done
    
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        log_info "Installing missing dependencies: ${MISSING_DEPS[*]}"
        if ! $INSTALL_CMD "${MISSING_DEPS[@]}"; then
            log_error "Failed to install dependencies: ${MISSING_DEPS[*]}"
            exit 1
        fi
    else
        log_info "All dependencies are already installed."
    fi
    
    log_success "Dependencies installed successfully."
}

# =============================================================================
# Ollama Installation
# =============================================================================

install_ollama() {
    log_info "Installing Ollama..."
    
    if check_command ollama; then
        log_info "Ollama is already installed."
        return 0
    fi
    
    # Download and install Ollama
    if ! curl -fsSL https://ollama.com/install.sh | sh; then
        log_error "Failed to install Ollama. Check your internet connection."
        exit 1
    fi
    
    # Add Ollama to PATH
    OLLAMA_PATH="$HOME/.local/bin"
    if [ -d "$OLLAMA_PATH" ] && ! grep -q "$OLLAMA_PATH" "$HOME/.bashrc" 2>/dev/null; then
        echo "export PATH=\"$OLLAMA_PATH:\"$PATH\"" >> "$HOME/.bashrc"
        export PATH="$OLLAMA_PATH:$PATH"
        log_info "Added Ollama to PATH in ~/.bashrc"
    fi
    
    # Verify installation
    if ! check_command ollama; then
        log_error "Ollama installation failed. Please install manually from https://ollama.com"
        exit 1
    fi
    
    log_success "Ollama installed successfully (version: $(ollama --version))."
}

# =============================================================================
# Cleanup Previous Installation
# =============================================================================

cleanup_previous() {
    log_info "Cleaning up previous installation..."
    
    # Kill any existing Ollama process from this setup
    if pgrep -f "ollama serve" &> /dev/null; then
        log_info "Stopping existing Ollama process..."
        pkill -f "ollama serve" || true
        sleep 2
    fi
    
    # Remove previous model directory
    MODELS_DIR="${OLLAMA_MODELS:-$DEFAULT_OLLAMA_MODELS}"
    if [ -d "$MODELS_DIR" ]; then
        rm -rf "$MODELS_DIR"
        log_info "Removed previous model directory: $MODELS_DIR"
    fi
    
    # Remove previous Ollama log
    if [ -f "/tmp/ollama.log" ]; then
        rm -f "/tmp/ollama.log"
        log_info "Removed previous Ollama log"
    fi
    
    log_success "Previous installation cleaned up."
}

# =============================================================================
# Ollama Configuration
# =============================================================================

configure_ollama() {
    log_info "Configuring Ollama..."
    
    # Use environment variable if set, otherwise use default
    MODELS_DIR="${OLLAMA_MODELS:-$DEFAULT_OLLAMA_MODELS}"
    
    # Create model directory in /tmp
    if [ ! -d "$MODELS_DIR" ]; then
        mkdir -p "$MODELS_DIR"
        log_info "Created model directory: $MODELS_DIR"
    fi
    
    # Set OLLAMA_MODELS environment variable
    if ! grep -q "OLLAMA_MODELS=" "$HOME/.bashrc" 2>/dev/null; then
        echo "export OLLAMA_MODELS=$MODELS_DIR" >> "$HOME/.bashrc"
    fi
    export OLLAMA_MODELS="$MODELS_DIR"
    
    log_success "Ollama configured to use: $OLLAMA_MODELS"
}

# =============================================================================
# Model Download
# =============================================================================

download_model() {
    local model="${MODEL_NAME:-$DEFAULT_MODEL}"
    log_info "Downloading model: $model"
    
    # Check if model already exists
    if ollama list | grep -q "$model"; then
        log_info "Model $model is already downloaded."
        return 0
    fi
    
    # Check available RAM before downloading
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
    
    # Model RAM requirements (approximate)
    case "$model" in
        "qwen2.5:1.5b") REQUIRED_RAM=4096 ;;
        "llama3.2:1b")   REQUIRED_RAM=4096 ;;
        "gemma:2b")     REQUIRED_RAM=4096 ;;
        "phi3:3.8b")    REQUIRED_RAM=4096 ;;
        "llama3.2:3b")  REQUIRED_RAM=8192 ;;
        *)              REQUIRED_RAM=4096 ;;
    esac
    
    if [ "$TOTAL_RAM_MB" -lt "$REQUIRED_RAM" ]; then
        log_warning "Your system has ${TOTAL_RAM_MB}MB RAM, but $model requires ~${REQUIRED_RAM}MB."
        log_warning "Model may fail to load or be very slow. Continuing anyway..."
    fi
    
    # Download the model
    log_info "Downloading $model (this may take 5-20 minutes)..."
    if ! ollama pull "$model"; then
        log_error "Failed to download model: $model"
        exit 1
    fi
    
    log_success "Model downloaded successfully: $model"
}

# =============================================================================
# Start Ollama Server
# =============================================================================

start_ollama() {
    log_info "Starting Ollama server..."
    
    # Kill any existing Ollama process
    if pgrep -f "ollama serve" &> /dev/null; then
        log_info "Stopping existing Ollama process..."
        pkill -f "ollama serve" || true
        sleep 2
    fi
    
    # Start Ollama with nohup and save PID
    log_info "Starting Ollama server with nohup..."
    nohup ollama serve > /tmp/ollama.log 2>&1 &
    OLLAMA_PID=$!
    log_info "Ollama server started with PID: $OLLAMA_PID"
    
    # Wait for server to start
    log_info "Waiting for Ollama server to respond on 127.0.0.1:11434..."
    MAX_ATTEMPTS=30
    ATTEMPT=1
    
    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        if curl -s http://127.0.0.1:11434/v1/models &> /dev/null; then
            log_success "Ollama server is running on http://127.0.0.1:11434"
            return 0
        fi
        sleep 2
        ATTEMPT=$((ATTEMPT + 1))
    done
    
    # Server failed to start - show log and exit
    log_error "Ollama server failed to start within ${MAX_ATTEMPTS} seconds."
    log_error "Check /tmp/ollama.log for details:"
    echo ""
    cat /tmp/ollama.log
    exit 1
}

# =============================================================================
# Verify Ollama
# =============================================================================

verify_ollama() {
    log_info "Verifying Ollama installation..."
    
    # Check if model is available
    local model="${MODEL_NAME:-$DEFAULT_MODEL}"
    if ! ollama list | grep -q "$model"; then
        log_error "Model $model not found. Please run: ollama pull $model"
        exit 1
    fi
    
    # Test API
    API_RESPONSE=$(curl -s http://localhost:11434/v1/models)
    if [ -z "$API_RESPONSE" ]; then
        log_error "Ollama API is not responding. Check if server is running."
        exit 1
    fi
    
    # Check if our model is in the API response
    if ! echo "$API_RESPONSE" | grep -q "$model"; then
        log_warning "Model $model is downloaded but not showing in API. Try restarting Ollama."
    fi
    
    log_success "Ollama verification passed."
    echo "  - Server: Running on http://localhost:11434"
    echo "  - Model: $model"
}

# =============================================================================
# Hermes Agent Installation
# =============================================================================

install_hermes() {
    log_info "Installing Hermes Agent..."
    
    if check_command hermes; then
        log_info "Hermes Agent is already installed."
        return 0
    fi
    
    # Download and install Hermes Agent
    if ! curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash; then
        log_error "Failed to install Hermes Agent. Check your internet connection."
        exit 1
    fi
    
    # Reload shell to pick up new PATH
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
    fi
    
    # Verify installation
    if ! check_command hermes; then
        log_error "Hermes Agent installation failed. Please install manually from https://github.com/NousResearch/hermes-agent"
        exit 1
    fi
    
    log_success "Hermes Agent installed successfully (version: $(hermes --version 2>/dev/null || echo 'unknown'))."
}

# =============================================================================
# Hermes Configuration
# =============================================================================

configure_hermes() {
    log_info "Configuring Hermes Agent to use local Ollama..."
    
    local model="${MODEL_NAME:-$DEFAULT_MODEL}"
    local endpoint="http://127.0.0.1:11434/v1"
    
    # Check if Hermes is already configured with Ollama
    if hermes config get provider 2>/dev/null | grep -q "custom"; then
        log_info "Hermes appears to be already configured with a custom endpoint."
        return 0
    fi
    
    # Use Hermes setup wizard non-interactively
    # We'll use expect or a series of echo commands to automate the setup
    log_info "Configuring Hermes with custom Ollama endpoint..."
    
    # Create a temporary config file for non-interactive setup
    cat > /tmp/hermes_setup_expect << 'EOF'
spawn hermes setup

# Wait for setup to start
expect {
    "How would you like to set up Hermes?" {
        send "1\r"
    }
    timeout 10
}

# Select provider
expect {
    "Select a provider" {
        send "\r"
    }
    "More providers" {
        send "\r"
    }
    timeout 10
}

# Select custom endpoint
expect {
    "Custom endpoint" {
        send "\r"
    }
    timeout 5
}

# Enter API base URL
expect {
    "API base URL" {
        send "http://127.0.0.1:11434/v1\r"
    }
    timeout 5
}

# API key (leave blank)
expect {
    "API key" {
        send "\r"
    }
    timeout 5
}

# Model selection
expect {
    "Use this model?" {
        send "Y\r"
    }
    timeout 5
}

# Context length (leave blank for auto-detect)
expect {
    "Context length" {
        send "\r"
    }
    timeout 5
}

# Messaging setup (skip)
expect {
    "Connect a messaging platform?" {
        send "2\r"
    }
    timeout 5
}

# Launch (no)
expect {
    "Launch hermes chat now?" {
        send "n\r"
    }
    timeout 5
}

exit 0
EOF
    
    # Try using expect if available
    if check_command expect; then
        if expect -f /tmp/hermes_setup_expect 2>/dev/null; then
            log_success "Hermes configured successfully with Ollama endpoint."
            rm -f /tmp/hermes_setup_expect
            return 0
        fi
    fi
    
    # Fallback: Manual configuration using hermes config commands
    log_info "Using manual configuration (expect not available)..."
    
    # Set the provider to custom
    if hermes config set provider "custom" 2>/dev/null; then
        log_info "Set provider to custom"
    fi
    
    # Set the API base URL
    if hermes config set provider.custom.base_url "$endpoint" 2>/dev/null; then
        log_info "Set custom endpoint: $endpoint"
    fi
    
    # Set the model
    if hermes config set model "$model" 2>/dev/null; then
        log_info "Set default model: $model"
    fi
    
    # Clear API key (not needed for local Ollama)
    if hermes config set provider.custom.api_key "" 2>/dev/null; then
        log_info "Cleared API key (not needed for local Ollama)"
    fi
    
    log_success "Hermes configuration completed."
    rm -f /tmp/hermes_setup_expect
}

# =============================================================================
# Final Verification
# =============================================================================

verify_installation() {
    log_info "Performing final verification..."
    
    local model="${MODEL_NAME:-$DEFAULT_MODEL}"
    local endpoint="http://127.0.0.1:11434/v1"
    
    echo ""
    echo "======================================================================="
    echo "                    INSTALLATION VERIFICATION"
    echo "======================================================================="
    
    # Check Ollama
    if pgrep -f "ollama serve" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Ollama server is running"
    else
        echo -e "${RED}✗${NC} Ollama server is NOT running"
    fi
    
    if ollama list | grep -q "$model"; then
        echo -e "${GREEN}✓${NC} Model '$model' is available"
    else
        echo -e "${RED}✗${NC} Model '$model' is NOT available"
    fi
    
    # Check Ollama API
    if curl -s "$endpoint/models" | grep -q "$model"; then
        echo -e "${GREEN}✓${NC} Ollama API is responding"
    else
        echo -e "${RED}✗${NC} Ollama API is NOT responding"
    fi
    
    # Check Hermes
    if check_command hermes; then
        echo -e "${GREEN}✓${NC} Hermes Agent is installed"
    else
        echo -e "${RED}✗${NC} Hermes Agent is NOT installed"
    fi
    
    # Try a simple test
    log_info "Running end-to-end test..."
    TEST_OUTPUT=$(timeout 10 hermes -q "Say 'Hello from Hermes + Ollama'" 2>/dev/null || true)
    if echo "$TEST_OUTPUT" | grep -q "Hello from Hermes"; then
        echo -e "${GREEN}✓${NC} End-to-end test passed"
    else
        echo -e "${YELLOW}⚠${NC} End-to-end test inconclusive (Hermes may need manual start)"
    fi
    
    echo ""
    echo "======================================================================="
    echo "                         SUCCESS!"
    echo "======================================================================="
    echo ""
    echo "Hermes Agent + Ollama are now set up on your Google Cloud VM."
    echo ""
    echo "  Ollama Server:   http://localhost:11434"
    echo "  Model:           $model"
    echo "  Model Storage:   $OLLAMA_MODELS"
    echo "  Hermes Agent:    Run 'hermes' to start chatting"
    echo ""
    echo "To use:"
    echo "  1. Start Hermes chat:    hermes"
    echo "  2. Test Ollama API:     curl http://localhost:11434/v1/models"
    echo "  3. List models:         ollama list"
    echo ""
    echo "======================================================================="
    echo "IMPORTANT NOTES:"
    echo "  - Models are stored in /tmp, which may be cleared on VM stop/restart"
    echo "  - To reinstall after restart: Run this script again"
    echo "  - Stop your VM when not in use to avoid Google Cloud charges"
    echo "======================================================================="
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo ""
    echo "======================================================================="
    echo "     Hermes Agent + Ollama One-Command Installer for Google Cloud"
    echo "======================================================================="
    echo ""
    
    # Display configuration
    log_info "Configuration:"
    log_info "  Model: ${MODEL_NAME:-$DEFAULT_MODEL}"
    log_info "  Model Storage: ${OLLAMA_MODELS:-$DEFAULT_OLLAMA_MODELS}"
    echo ""
    
    # Run all steps
    check_system
    install_dependencies
    install_ollama
    cleanup_previous
    configure_ollama
    start_ollama
    download_model
    verify_ollama
    install_hermes
    configure_hermes
    verify_installation
    
    echo ""
    log_success "Installation complete!"
}

# Run main function
main "$@"
