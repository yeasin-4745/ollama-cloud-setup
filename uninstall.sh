#!/bin/bash

# Hermes Agent + Ollama Uninstaller for Google Cloud VM
#
# This script removes Hermes Agent, Ollama, and related files from your system.
# It does NOT delete your Google Cloud VM or persistent disks.
#
# Usage:
#   ./uninstall.sh
#
# WARNING: This will remove:
#   - Ollama and all downloaded models
#   - Hermes Agent and its configuration
#   - Temporary files in /tmp/ollama_models
#
# It will NOT remove:
#   - System dependencies (curl, git, python3, etc.)
#   - Your home directory or other personal files

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    command -v "$1" &> /dev/null
}

# =============================================================================
# Confirmation
# =============================================================================

confirm_uninstall() {
    echo ""
    echo "======================================================================="
    echo "                    UNINSTALL CONFIRMATION"
    echo "======================================================================="
    echo ""
    echo "This script will remove the following:"
    echo "  - Ollama binary and all downloaded models"
    echo "  - Hermes Agent and its configuration (~/.hermes)"
    echo "  - /tmp/ollama_models directory"
    echo "  - Ollama environment variables from ~/.bashrc"
    echo ""
    echo "It will NOT remove:"
    echo "  - System dependencies (curl, git, python3, etc.)"
    echo "  - Your home directory or other personal files"
    echo ""
    read -p "Do you want to continue? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstall cancelled."
        exit 0
    fi
}

# =============================================================================
# Remove Ollama
# =============================================================================

remove_ollama() {
    log_info "Removing Ollama..."
    
    # Stop Ollama server
    if pgrep -f "ollama serve" &> /dev/null; then
        log_info "Stopping Ollama server..."
        pkill -f "ollama serve" || true
        sleep 2
    fi
    
    # Remove Ollama binary
    OLLAMA_BIN="$HOME/.local/bin/ollama"
    if [ -f "$OLLAMA_BIN" ]; then
        rm -f "$OLLAMA_BIN"
        log_info "Removed Ollama binary"
    fi
    
    # Remove Ollama directory
    OLLAMA_DIR="$HOME/.ollama"
    if [ -d "$OLLAMA_DIR" ]; then
        rm -rf "$OLLAMA_DIR"
        log_info "Removed Ollama directory"
    fi
    
    # Remove models from /tmp
    OLLAMA_MODELS="/tmp/ollama_models"
    if [ -d "$OLLAMA_MODELS" ]; then
        rm -rf "$OLLAMA_MODELS"
        log_info "Removed /tmp/ollama_models"
    fi
    
    # Remove Ollama from PATH in ~/.bashrc
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/ollama/d' "$HOME/.bashrc"
        log_info "Removed Ollama from ~/.bashrc"
    fi
    
    # Remove OLLAMA_MODELS from ~/.bashrc
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/OLLAMA_MODELS/d' "$HOME/.bashrc"
        log_info "Removed OLLAMA_MODELS from ~/.bashrc"
    fi
    
    log_success "Ollama removed successfully."
}

# =============================================================================
# Remove Hermes Agent
# =============================================================================

remove_hermes() {
    log_info "Removing Hermes Agent..."
    
    # Remove Hermes directory
    HERMES_DIR="$HOME/.hermes"
    if [ -d "$HERMES_DIR" ]; then
        rm -rf "$HERMES_DIR"
        log_info "Removed Hermes directory"
    fi
    
    # Remove Hermes binary (if installed in local bin)
    HERMES_BIN="$HOME/.local/bin/hermes"
    if [ -f "$HERMES_BIN" ]; then
        rm -f "$HERMES_BIN"
        log_info "Removed Hermes binary"
    fi
    
    # Remove Hermes from PATH in ~/.bashrc
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/hermes/d' "$HOME/.bashrc"
        log_info "Removed Hermes from ~/.bashrc"
    fi
    
    # Remove Hermes-related environment variables
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/HERMES_/d' "$HOME/.bashrc"
        log_info "Removed Hermes environment variables from ~/.bashrc"
    fi
    
    log_success "Hermes Agent removed successfully."
}

# =============================================================================
# Clean up temporary files
# =============================================================================

cleanup_temp_files() {
    log_info "Cleaning up temporary files..."
    
    # Remove /tmp/ollama_models if it still exists
    if [ -d "/tmp/ollama_models" ]; then
        rm -rf "/tmp/ollama_models"
        log_info "Removed /tmp/ollama_models"
    fi
    
    # Remove any temporary setup files
    if [ -f "/tmp/hermes_setup_expect" ]; then
        rm -f "/tmp/hermes_setup_expect"
        log_info "Removed temporary setup files"
    fi
    
    log_success "Temporary files cleaned up."
}

# =============================================================================
# Verify removal
# =============================================================================

verify_removal() {
    echo ""
    echo "======================================================================="
    echo "                    VERIFICATION"
    echo "======================================================================="
    echo ""
    
    # Check Ollama
    if check_command ollama; then
        echo -e "${RED}✗${NC} Ollama binary still exists"
    else
        echo -e "${GREEN}✓${NC} Ollama binary removed"
    fi
    
    if [ -d "$HOME/.ollama" ]; then
        echo -e "${RED}✗${NC} Ollama directory still exists"
    else
        echo -e "${GREEN}✓${NC} Ollama directory removed"
    fi
    
    if [ -d "/tmp/ollama_models" ]; then
        echo -e "${RED}✗${NC} /tmp/ollama_models still exists"
    else
        echo -e "${GREEN}✓${NC} /tmp/ollama_models removed"
    fi
    
    # Check Hermes
    if check_command hermes; then
        echo -e "${RED}✗${NC} Hermes binary still exists"
    else
        echo -e "${GREEN}✓${NC} Hermes binary removed"
    fi
    
    if [ -d "$HOME/.hermes" ]; then
        echo -e "${RED}✗${NC} Hermes directory still exists"
    else
        echo -e "${GREEN}✓${NC} Hermes directory removed"
    fi
    
    echo ""
    echo "======================================================================="
    echo "                    UNINSTALL COMPLETE"
    echo "======================================================================="
    echo ""
    echo "To completely reset your environment:"
    echo "  1. Reboot your VM: sudo reboot"
    echo "  2. Or create a new VM instance"
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo ""
    echo "======================================================================="
    echo "     Hermes Agent + Ollama Uninstaller for Google Cloud"
    echo "======================================================================="
    echo ""
    
    confirm_uninstall
    remove_ollama
    remove_hermes
    cleanup_temp_files
    verify_removal
    
    echo ""
    log_success "Uninstallation complete!"
}

# Run main function
main "$@"
