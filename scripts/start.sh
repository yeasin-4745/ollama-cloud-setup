#!/bin/bash

# Start Ollama server and pull lightweight model (qwen2.5:1.5b)
# Usage: ./scripts/start.sh

set -e

export OLLAMA_MODELS=/tmp/ollama_models
mkdir -p "$OLLAMA_MODELS"

echo "Starting Ollama server..."
ollama serve &

# Wait for server to initialize
sleep 5

echo "Pulling lightweight model: qwen2.5:1.5b..."
ollama pull qwen2.5:1.5b

echo "Ollama server is running. Models stored in: $OLLAMA_MODELS"
echo "API endpoint: http://localhost:11434/v1"
