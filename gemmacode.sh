#!/bin/bash
# Start SuperGemma (reasoning OFF) + LiteLLM and launch Claude Code

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

LLAMA_DIR="$HOME/llama.cpp"
MODEL="$HOME/models/supergemma4/supergemma4-26b-Q4_K_M.gguf"
TEMPLATE="$LLAMA_DIR/models/templates/google-gemma-4-31B-it-interleaved.jinja"

# 1. Start SuperGemma with reasoning OFF
# If already running, restart it with reasoning off for coding mode
if curl -s http://localhost:6969/health | grep -q "ok" 2>/dev/null; then
  # Check if it's already running in no-reasoning mode
  if pgrep -f "reasoning off" > /dev/null; then
    echo "SuperGemma already running (reasoning off)."
  else
    echo "Restarting SuperGemma with reasoning OFF for coding..."
    pkill -f "llama-server" 2>/dev/null
    sleep 2
    nohup "$LLAMA_DIR/build/bin/llama-server" \
      -m "$MODEL" \
      --chat-template-file "$TEMPLATE" \
      -ngl 18 \
      --ctx-size 131072 \
      --cache-type-k q4_0 \
      --cache-type-v q4_0 \
      -t 8 \
      --reasoning off \
      --host 0.0.0.0 \
      --port 6969 \
      --alias supergemma4 > /tmp/supergemma.log 2>&1 &
    echo "  Waiting for model to reload..."
    for i in {1..30}; do
      sleep 2
      if curl -s http://localhost:6969/health | grep -q "ok" 2>/dev/null; then
        echo "  SuperGemma ready (reasoning off)."
        break
      fi
    done
  fi
else
  echo "Starting SuperGemma4 (reasoning off)..."
  nohup "$LLAMA_DIR/build/bin/llama-server" \
    -m "$MODEL" \
    --chat-template-file "$TEMPLATE" \
    -ngl 18 \
    --ctx-size 131072 \
    --cache-type-k q4_0 \
    --cache-type-v q4_0 \
    -t 8 \
    --reasoning off \
    --host 0.0.0.0 \
    --port 6969 \
    --alias supergemma4 > /tmp/supergemma.log 2>&1 &
  echo "  Waiting for model to load..."
  for i in {1..30}; do
    sleep 2
    if curl -s http://localhost:6969/health | grep -q "ok" 2>/dev/null; then
      echo "  SuperGemma ready."
      break
    fi
  done
fi

# 2. Start LiteLLM if not running
if ! curl -s http://localhost:4000/health 2>/dev/null | grep -q "healthy"; then
  echo "Starting LiteLLM proxy..."
  nohup litellm --config ~/litellm-config.yaml --port 4000 > /tmp/litellm.log 2>&1 &
  sleep 4
  echo "  LiteLLM ready."
else
  echo "LiteLLM already running."
fi

echo ""
echo "Launching Claude Code → SuperGemma4 (reasoning off, localhost:4000)"
echo "To switch back to real Claude: just run 'claude' normally"
echo ""

# 3. Launch Claude Code pointed at LiteLLM
ANTHROPIC_BASE_URL=http://localhost:4000 ANTHROPIC_API_KEY=local-supergemma claude "$@"
