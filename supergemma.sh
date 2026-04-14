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
#   - KV cache quantized to q4_0 → enables 128K context within 12GB VRAM
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
echo "  Context:  131072 tokens (128K, KV cache quantized to q4_0)"
echo "  API:      http://localhost:6969/v1"
echo "  UI:       http://localhost:6969"
echo ""
echo "Press Ctrl+C to stop."
echo ""

exec "$LLAMA_DIR/build/bin/llama-server" \
  -m "$MODEL" \
  --chat-template-file "$TEMPLATE" \
  -ngl 18 \
  --ctx-size 131072 \
  --cache-type-k q4_0 \
  --cache-type-v q4_0 \
  -t 8 \
  --host 0.0.0.0 \
  --port 6969 \
  --alias supergemma4
