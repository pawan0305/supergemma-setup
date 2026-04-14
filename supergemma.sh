#!/bin/bash
# =============================================================================
# SuperGemma4 26B — Start llama-server (OpenAI-compatible API)
#
# Usage:
#   ~/supergemma.sh              # start server (foreground)
#   ~/supergemma.sh &            # start in background
#
# API endpoint: http://localhost:8080/v1
# Health check: http://localhost:8080/health
# Web UI:       http://localhost:8080 (built-in chat UI)
#
# Hardware tested: RTX 3080 Ti 12GB VRAM + 32GB RAM
#   - 18 GPU layers  → fits in 12GB VRAM
#   - Rest on CPU RAM → ~7.4GB RAM used
#   - Speed: ~40 tokens/sec generation, ~90 tokens/sec prompt processing
# =============================================================================

LLAMA_DIR="$HOME/llama.cpp"
MODEL="$HOME/models/supergemma4/supergemma4-26b-Q4_K_M.gguf"
TEMPLATE="$LLAMA_DIR/models/templates/google-gemma-4-31B-it-interleaved.jinja"

# Sanity checks
if [ ! -f "$MODEL" ]; then
  echo "ERROR: Model not found at $MODEL"
  echo "Run ./install.sh first."
  exit 1
fi

if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: Chat template not found at $TEMPLATE"
  exit 1
fi

echo "Starting SuperGemma4 26B..."
echo "  Model:    $MODEL"
echo "  GPU layers: 18 / ~46 total (rest on CPU)"
echo "  Context:  8192 tokens"
echo "  API:      http://localhost:8080/v1"
echo "  UI:       http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop."
echo ""

exec "$LLAMA_DIR/build/bin/llama-server" \
  -m "$MODEL" \
  --chat-template-file "$TEMPLATE" \
  -ngl 18 \
  --ctx-size 8192 \
  -t 8 \
  --host 0.0.0.0 \
  --port 8080 \
  --alias supergemma4
