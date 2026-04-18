#!/bin/bash
# =============================================================================
# SuperGemma4 26B — Full Install Script
# Tested on: Ubuntu 24.04, RTX 3090 24GB VRAM, 32GB RAM, CUDA 12.4
# Note: Part of ~/Local LLM setup. Run ~/Local LLM/install.sh for full setup.
# =============================================================================

set -e

MODELS_DIR="$HOME/Local LLM/models/supergemma4"
LLAMA_DIR="$HOME/Local LLM/llama.cpp"
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

# ── Step 5: Install scripts ───────────────────────────────────────────────────
echo ""
echo "[5/6] Installing scripts to home directory..."
SCRIPT_DIR="$(dirname "$0")"
cp "$SCRIPT_DIR/supergemma.sh" "$HOME/supergemma.sh"
cp "$SCRIPT_DIR/gemmacode.sh" "$HOME/gemmacode.sh"
cp "$SCRIPT_DIR/litellm-config.yaml" "$HOME/litellm-config.yaml"
chmod +x "$HOME/supergemma.sh" "$HOME/gemmacode.sh"
echo "  Scripts installed."

# ── Step 6: Install Python tools & shell aliases ──────────────────────────────
echo ""
echo "[6/6] Installing uv, LiteLLM, Open WebUI and shell aliases..."

# Install uv (Python package manager)
if ! command -v uv &>/dev/null && [ ! -f "$HOME/.local/bin/uv" ]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"

# Install LiteLLM
uv tool install 'litellm[proxy]'

# Install Open WebUI + Python 3.13 fix
uv tool install open-webui
uv pip install --python ~/.local/share/uv/tools/open-webui/bin/python audioop-lts 2>/dev/null || true

# Add aliases to ~/.bashrc (skip if already present)
if ! grep -q "SuperGemma shortcuts" "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" << 'ALIASES'

# SuperGemma shortcuts
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
alias startgemma="nohup ~/supergemma.sh > /tmp/supergemma.log 2>&1 & echo SuperGemma started, PID: $!"
alias stopgemma="pkill -f llama-server && echo SuperGemma stopped"
alias gemmalogs="tail -f /tmp/supergemma.log"
alias startwebui="OPENAI_API_BASE_URL=http://localhost:6969/v1 OPENAI_API_KEY=none nohup open-webui serve --port 3000 > /tmp/openwebui.log 2>&1 & echo Open WebUI started, PID: $!"
alias stopwebui="pkill -f open-webui && echo Open WebUI stopped"
alias startlitellm="nohup litellm --config ~/litellm-config.yaml --port 4000 > /tmp/litellm.log 2>&1 & echo LiteLLM started, PID: $!"
alias stoplitellm="pkill -f litellm && echo LiteLLM stopped"
alias gemmacode="~/gemmacode.sh"
ALIASES
  echo "  Aliases added to ~/.bashrc"
else
  echo "  Aliases already present in ~/.bashrc, skipping."
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Done! Available commands (open a new terminal):     ║"
echo "║                                                       ║"
echo "║  startgemma   — start SuperGemma4 in background      ║"
echo "║  stopgemma    — stop SuperGemma4                      ║"
echo "║  gemmalogs    — watch live logs                       ║"
echo "║  startwebui   — start Open WebUI (port 3000)          ║"
echo "║  stopwebui    — stop Open WebUI                       ║"
echo "║  startlitellm — start LiteLLM proxy (port 4000)      ║"
echo "║  stoplitellm  — stop LiteLLM proxy                   ║"
echo "║  gemmacode    — Claude Code via SuperGemma4           ║"
echo "║                                                       ║"
echo "║  Or run everything at once:  gemmacode               ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
