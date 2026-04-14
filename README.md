# SuperGemma4 26B — Local LLM Setup

Run **SuperGemma4 26B** (uncensored Gemma 4 finetune) fully locally via llama.cpp with an OpenAI-compatible API.

Tested hardware: **RTX 3080 Ti 12GB VRAM + 32GB RAM**

---

## What is SuperGemma4?

SuperGemma4 is an uncensored finetune of Google's **Gemma 4 26B** — a Mixture-of-Experts model with 25.2B total parameters but only **~4B active per token** (very efficient). It includes built-in reasoning/thinking mode. Good for coding, reasoning, and agent workflows.

- Model: [Jiunsong/supergemma4-26b-uncensored-gguf-v2](https://huggingface.co/Jiunsong/supergemma4-26b-uncensored-gguf-v2)
- Quantization: Q4_K_M (~16GB on disk)
- Backend: [llama.cpp](https://github.com/ggml-org/llama.cpp)

---

## Requirements

| Component | Minimum |
|-----------|---------|
| GPU VRAM  | 12GB (RTX 3080 Ti / 3060 12GB) |
| RAM       | 32GB (model spills ~7.4GB to RAM) |
| Disk      | 20GB free |
| OS        | Ubuntu 22.04+ |
| CUDA      | 12.x (check: `nvidia-smi`) |

> **Note:** If you have 24GB VRAM (RTX 3090/4090), change `-ngl 18` to `-ngl 999` in `supergemma.sh` to load the entire model on GPU for maximum speed.

---

## Fresh Install (from scratch)

```bash
# 1. Clone this repo
git clone https://github.com/pawan0305/supergemma-setup.git
cd supergemma-setup

# 2. Run the installer
chmod +x install.sh
./install.sh
```

The installer will:
1. Install `build-essential`, `cmake`, `git`, `wget`
2. Clone and build **llama.cpp** from source with CUDA support
3. Download the SuperGemma4 26B Q4_K_M GGUF (~16GB)
4. Copy `supergemma.sh` to your home directory

---

## Start the Server

```bash
~/supergemma.sh
```

That's it. The server starts and exposes:

| Endpoint | URL |
|----------|-----|
| OpenAI-compatible API | `http://localhost:8080/v1` |
| Health check | `http://localhost:8080/health` |
| Built-in chat UI | `http://localhost:8080` |

---

## Use the API

### curl
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "supergemma4",
    "messages": [{"role": "user", "content": "Write a Python quicksort."}],
    "max_tokens": 2000
  }'
```

### Python (OpenAI SDK)
```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="none"  # no key needed for local
)

response = client.chat.completions.create(
    model="supergemma4",
    messages=[{"role": "user", "content": "Write a Python quicksort."}],
    max_tokens=2000
)
print(response.choices[0].message.content)
```

### Use with any OpenAI-compatible tool
Point any tool that accepts a custom base URL to `http://localhost:8080/v1`.
Works with: LangChain, LlamaIndex, OpenClaw, Hermes agent, Continue.dev, etc.

---

## Performance (RTX 3080 Ti 12GB)

| Metric | Speed |
|--------|-------|
| Prompt processing | ~90 tokens/sec |
| Generation | ~40 tokens/sec |
| GPU layers | 18 of ~46 (rest on CPU RAM) |
| VRAM used | ~10.6GB of 12GB |
| RAM used | ~7.4GB |

---

## Reasoning Mode

SuperGemma4 uses built-in thinking/reasoning by default. The API returns a `reasoning_content` field alongside the regular `content`. This is normal — the model thinks before answering.

To disable reasoning in API calls:
```json
{ "thinking": false }
```

---

## Run in Background

```bash
nohup ~/supergemma.sh > /tmp/supergemma.log 2>&1 &
echo "Server PID: $!"

# Check logs
tail -f /tmp/supergemma.log

# Stop server
pkill -f "llama-server"
```

---

## Updating llama.cpp

If Gemma 4 support improves or you hit bugs:

```bash
cd ~/llama.cpp
git pull
cmake --build build --config Release -j$(nproc)
```

---

## Troubleshooting

**Out of memory (OOM) on GPU:**
Reduce GPU layers in `supergemma.sh`:
```bash
-ngl 14   # use less VRAM
```

**Model loads slowly / lots of CPU usage:**
This is normal. The model is partially on CPU RAM. First token is slower, generation after that is ~40 t/s.

**`llama-server` not found:**
The build may have failed. Re-run:
```bash
cd ~/llama.cpp && cmake -B build -DGGML_CUDA=ON && cmake --build build --config Release -j$(nproc)
```

**Chat template error:**
Make sure you're on a recent llama.cpp build that includes the Gemma 4 interleaved template:
```bash
ls ~/llama.cpp/models/templates/google-gemma-4-31B-it-interleaved.jinja
```
If missing, `git pull` in `~/llama.cpp` and rebuild.

---

## Hardware Notes

- This setup was built for **RTX 3080 Ti (12GB)**. The 16GB model doesn't fully fit in VRAM, so 18 layers go to GPU and the rest spill to RAM. Speed is still ~40 t/s.
- With **RTX 3090 / 4090 (24GB)**: change `-ngl 18` → `-ngl 999` to load everything on GPU. Expect 60-80+ t/s.
- With **less than 12GB VRAM**: drop `-ngl` further (try `-ngl 10`) and accept slower speeds.

---

## Quick Commands

Add these to your shell by running `install.sh` or manually:

```bash
alias startgemma="nohup ~/supergemma.sh > /tmp/supergemma.log 2>&1 & echo SuperGemma started, PID: $!"
alias stopgemma="pkill -f llama-server && echo SuperGemma stopped"
alias gemmalogs="tail -f /tmp/supergemma.log"
```

| Command | Action |
|---------|--------|
| `startgemma` | Start server in background |
| `stopgemma` | Kill server |
| `gemmalogs` | Watch live logs |
