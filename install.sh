#!/bin/bash
# =============================================================================
# SuperGemma4 26B — Full Install Script
# Tested on: Ubuntu 24.04, RTX 3080 Ti 12GB VRAM, 32GB RAM, CUDA 12.4
# =============================================================================

set -e

MODELS_DIR="$HOME/models/supergemma4"
LLAMA_DIR="$HOME/llama.cpp"
MODEL_FILE="supergemma4-26b-Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/Jiunsong/supergemma4-26b-uncensored-gguf-v2/resolve/main/supergemma4-26b-uncensored-fast-v2-Q4_K_M.gguf"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║        SuperGemma4 26B — Setup Script                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Dependencies ─────────────────────────────────────────────────────
echo "[1/5] Installing build dependencies..."
sudo apt update -q
sudo apt install -y build-essential cmake git wget

# ── Step 2: Clone & build llama.cpp ──────────────────────────────────────────
echo ""
echo "[2/5] Cloning and building llama.cpp with CUDA support..."

if [ -d "$LLAMA_DIR" ]; then
  echo "  llama.cpp already exists at $LLAMA_DIR, pulling latest..."
  git -C "$LLAMA_DIR" pull
else
  git clone https://github.com/ggml-org/llama.cpp "$LLAMA_DIR"
fi

cd "$LLAMA_DIR"
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release -j$(nproc)
echo "  Build complete."

# ── Step 3: Download model ────────────────────────────────────────────────────
echo ""
echo "[3/5] Downloading SuperGemma4 26B Q4_K_M (~16GB)..."
mkdir -p "$MODELS_DIR"

if [ -f "$MODELS_DIR/$MODEL_FILE" ]; then
  echo "  Model already exists, skipping download."
else
  wget -c "$MODEL_URL" -O "$MODELS_DIR/$MODEL_FILE"
fi

# ── Step 4: Verify chat template ──────────────────────────────────────────────
echo ""
echo "[4/5] Checking Gemma 4 chat template..."
TEMPLATE="$LLAMA_DIR/models/templates/google-gemma-4-31B-it-interleaved.jinja"
if [ ! -f "$TEMPLATE" ]; then
  echo "  ERROR: Chat template not found at $TEMPLATE"
  echo "  Your llama.cpp build may be outdated. Run: git -C $LLAMA_DIR pull && cmake --build $LLAMA_DIR/build --config Release -j\$(nproc)"
  exit 1
fi
echo "  Template found."

# ── Step 5: Install startup script ───────────────────────────────────────────
echo ""
echo "[5/5] Installing supergemma.sh to ~/supergemma.sh..."
cp "$(dirname "$0")/supergemma.sh" "$HOME/supergemma.sh"
chmod +x "$HOME/supergemma.sh"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Done! Start SuperGemma4 with:  ~/supergemma.sh      ║"
echo "║  API will be at: http://localhost:8080/v1             ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
