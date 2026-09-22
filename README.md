# Portable USB Local AI 🚀
### Run & Switch GGUF Reasoning & Vision AI Models Anywhere — Straight from a USB Drive

[![Platform](https://img.shields.io/badge/Platform-Windows%20x64-blue.svg)](https://github.com/remsaw/USB_local_AI)
[![llama.cpp](https://img.shields.io/badge/Powered%20by-llama.cpp-orange.svg)](https://github.com/ggml-org/llama.cpp)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Zero Install](https://img.shields.io/badge/Dependencies-Zero%20(No%20Python%2FNo%20CUDA)-brightgreen.svg)](https://github.com/remsaw/USB_local_AI)

**USB Local AI** is a complete, self-contained, 100% offline portable AI workstation that runs directly from any USB flash drive or portable SSD on any Windows computer.

No Python, no PyTorch, no Docker, no CUDA configuration, and no administrative privileges required. Simply plug in your USB drive, run `Start-AI-Router.bat`, and chat with state-of-the-art **Text Reasoning** (DeepSeek-R1, Qwen Thinking) and **Multimodal Vision** models with full image upload capabilities!

---

## 🌟 Key Features

- 🔌 **100% Portable & Plug-and-Play**: Runs directly from any USB drive (drive letters like `D:`, `E:`, `F:` are resolved dynamically). Leave zero trace on the host computer.
- 🖼️ **Full Multimodal Vision & Image Upload**: Upload images, diagrams, receipts, screenshots, and photos via drag-and-drop or paperclip attachment in the Web UI.
- 🧠 **Deep Reasoning Support**: Native support for DeepSeek-R1 and Qwen Thinking models with visible chain-of-thought token streams.
- 🔀 **Dynamic Model Router**: Switch between multiple models instantly from a single dropdown without restarting the server.
- 💾 **Smart RAM Management (`--models-max 1`)**: Holds unlimited models on your USB drive while loading only one model into RAM at a time, preventing Out-Of-Memory (OOM) crashes on 8GB/16GB machines.
- 🌐 **Modern Built-in Web UI**: Clean, responsive browser interface served locally at `http://127.0.0.1:8080`.
- 🔌 **OpenAI-Compatible API**: Seamlessly connects with third-party tools like Continue.dev, Cursor, LibreChat, Chatbox, and Obsidian.

---

## 💡 Overcoming the Limits of Local Models

Running local AI on ordinary laptops and desktop computers traditionally faces major roadblocks. Here is how this project overcomes each of them:

### 1. Overcoming the RAM / VRAM Barrier
* **The Problem:** Modern LLMs often require 16GB–32GB+ of high-end GPU VRAM. Loading multiple models crashes the system with Out-Of-Memory (OOM) errors.
* **The Solution:** 
  - **Dynamic Model Router (`--models-max 1`)**: You can store hundreds of gigabytes of models on your USB drive. When you switch from a reasoning model to a vision model in the Web UI, the router automatically unloads the previous model from RAM before loading the new one.
  - **Smart Quantization (`Q4_K_M` / `Q3_K_M`)**: By quantizing weights to 4-bit or 3-bit, models retain >99% of their original reasoning capability while reducing memory requirements by 70–75%. An 8GB RAM computer can easily run 3B–4B models; a 16GB RAM laptop can comfortably run 7B–14B models.

### 2. Overcoming the Hardware & GPU Dependency
* **The Problem:** Many users don't have dedicated NVIDIA GPUs (e.g. office laptops, MacBooks in BootCamp, Intel/AMD iGPUs).
* **The Solution:** Built on `llama.cpp`'s highly optimized CPU inference engine utilizing modern CPU instruction sets (**AVX2**, **AVX-512**, and **FMA**). It delivers fast token generation directly on your standard CPU without needing any GPU drivers.

### 3. Overcoming Multimodal / Vision Projector Complexity
* **The Problem:** Vision-Language Models (VLMs) require two separate components: the language model and a multimodal projector (`mmproj`). If loaded incorrectly, the Web UI disables image attachments and treats the model as plain text.
* **The Solution:** Our auto-discovery script (`scripts/scan_models.ps1`) automatically scans your `Models/` folder on every launch, detects `mmproj` projector files, pairs them with their vision models, and configures the router so that the Web UI immediately unlocks the image upload button.

### 4. Overcoming Slow USB Drive Bottlenecks
* **The Problem:** Loading multi-gigabyte models over slow USB drives can take minutes.
* **The Solution:**
  - Memory-mapping (`mmap`) reads only the necessary tensor pages into memory on demand.
  - Format your USB drive as **exFAT** or **NTFS** (FAT32 cannot store files larger than 4GB).
  - Use a **USB 3.0 / 3.1 / 3.2 Gen 2** flash drive or a portable **NVMe SSD** enclosure (1000+ MB/s read speeds load even 14B models in 3–5 seconds!).

---

## 📥 Recommended Models & Download Links

Because model files are several gigabytes each, they are not included in this repository. Download your desired models from the curated links below and place them in the `Models\` folder.

### 🖼️ Vision Models (Supports Image Uploads)
> **Note:** For vision models, download **BOTH** the model file and its matching `mmproj` projector file, and place them inside a subfolder under `Models/`.

| Model | Recommended Quant | Min. RAM | Direct Hugging Face Links |
| :--- | :---: | :---: | :--- |
| **Qwen2.5-VL-7B-Instruct** *(Best overall vision)* | Q4_K_M (~4.7 GB) | 12 GB | [Model File](https://huggingface.co/Qwen/Qwen2.5-VL-7B-Instruct-GGUF/resolve/main/qwen2.5-vl-7b-instruct-q4_k_m.gguf) + [mmproj File](https://huggingface.co/Qwen/Qwen2.5-VL-7B-Instruct-GGUF/resolve/main/mmproj-Qwen2.5-VL-7B-Instruct-f16.gguf) |
| **Qwen2.5-VL-3B-Instruct** *(Fast & lightweight)* | Q4_K_M (~2.1 GB) | 8 GB | [Model File](https://huggingface.co/Qwen/Qwen2.5-VL-3B-Instruct-GGUF/resolve/main/qwen2.5-vl-3b-instruct-q4_k_m.gguf) + [mmproj File](https://huggingface.co/Qwen/Qwen2.5-VL-3B-Instruct-GGUF/resolve/main/mmproj-Qwen2.5-VL-3B-Instruct-f16.gguf) |
| **Qwen3-VL-4B-Instruct** *(Compact VLM)* | Q4_K_M (~2.5 GB) | 8 GB | Search `Qwen3-VL GGUF` on Hugging Face |
| **Gemma-3-4B-IT** *(Google multimodal)* | Q4_K_M (~2.7 GB) | 8 GB | [Gemma-3 GGUF Repositories](https://huggingface.co/models?search=gemma-3-4b-it-gguf) |

### 🧠 Deep Reasoning & Thinking Models
> Place standalone `.gguf` files directly into `Models\`.

| Model | Recommended Quant | Min. RAM | Direct Hugging Face Links |
| :--- | :---: | :---: | :--- |
| **DeepSeek-R1-Distill-Qwen-7B** *(Top math/logic)* | Q4_K_M (~4.7 GB) | 8 GB | [Download Q4_K_M](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf) |
| **DeepSeek-R1-Distill-Qwen-14B** *(Deep reasoning)* | Q3_K_M (~7.3 GB) | 16 GB | [Download Q3_K_M](https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-14B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-14B-Q3_K_M.gguf) |
| **Qwen2.5-Coder-7B-Instruct** *(Coding expert)* | Q4_K_M (~4.7 GB) | 8 GB | [Download Q4_K_M](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q4_k_m.gguf) |
| **Llama-3.2-3B-Instruct** *(Ultra-fast general)* | Q4_K_M (~2.0 GB) | 8 GB | [Download Q4_K_M](https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf) |

---

## 📁 Directory Structure

```text
USB Drive (e.g. E:\)
├── Start-AI-Router.bat          <-- Double-click to launch router & Web UI
├── Install-Llama-Router.bat     <-- Run once to download llama.cpp server
├── models.ini.template          <-- Template configuration reference
├── scripts\
│   └── scan_models.ps1          <-- Auto-detects models & pairs vision projectors
├── Models\                      <-- Drop your models here
│   ├── README.md
│   ├── DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf      (Text model)
│   ├── qwen3-4b-thinking-2507.Q4_K_M.gguf            (Text model)
│   └── Qwen3VL-4B-Instruct\                          (Vision folder)
│       ├── Qwen3VL-4B-Instruct-Q4_K_M.gguf          (Model file)
│       └── mmproj-Qwen3VL-4B-Instruct-F16.gguf       (Projector file)
└── llama-router\                <-- Downloaded automatically by installer
    └── llama-server.exe
```

---

## 🚀 Quick Start Guide (3 Simple Steps)

### Step 1: Download or Clone this Repository to your USB Drive
```powershell
# Clone directly to your USB drive root (e.g. E:\)
git clone https://github.com/remsaw/USB_local_AI.git E:\
```
*Or download as a ZIP from GitHub and extract the contents to your USB drive.*

### Step 2: Install llama.cpp Server (Run Once)
Double-click **`Install-Llama-Router.bat`**.
- It downloads the official portable Windows x64 CPU build of `llama.cpp`.
- Extracts all required executables and libraries to `llama-router\`.

### Step 3: Add Models & Launch!
1. Download one or more models from the [Recommended Models](#-recommended-models--download-links) section into the `Models\` folder.
2. Double-click **`Start-AI-Router.bat`**.
3. Your default browser will automatically open to `http://127.0.0.1:8080`.


---

## 📸 How to Upload Images & Use Vision Models

1. In the Web UI (top-left dropdown), select your **Vision Model** (e.g., `Qwen3VL-4B-Instruct` or `Qwen2.5-VL-7B`).
2. The chat box will display a **Paperclip Icon** or allow you to **Drag-and-Drop** images directly into the chat window.
3. You can ask:
   - *"Transcribe all text from this receipt/document (OCR)."*
   - *"Explain this architecture diagram step-by-step."*
   - *"Analyze this chart and summarize key trends."*
   - *"Convert this screenshot of a webpage or UI into clean HTML/Tailwind CSS."*
   - *"What is causing this software error in the screenshot?"*

---

## ⚙️ Advanced Customization & Performance Tuning

### Memory and Context Size
By default, models run with a context size of `8192` tokens. You can adjust this for individual models by editing the generated `models.ini`:
```ini
[my-model]
model = Models/my-model.gguf
ctx-size = 4096   ; Lower to 4096 to save RAM on 8GB machines
n-gpu-layers = 0  ; 0 for CPU; set higher if using a GPU build
```

### Third-Party Apps (OpenAI Compatible API)
The server runs an OpenAI-compatible REST API at:
- **Base URL**: `http://127.0.0.1:8080/v1`
- **Chat Endpoint**: `http://127.0.0.1:8080/v1/chat/completions`
- **Models Endpoint**: `http://127.0.0.1:8080/v1/models`
- **API Key**: Any string (or leave empty)

---

## ❓ Troubleshooting & FAQ

<details>
<summary><b>The image upload paperclip is not visible in the Web UI.</b></summary>
Ensure you have downloaded both the model <code>.gguf</code> and the matching <code>mmproj-*.gguf</code> file, and placed them in the same subfolder under <code>Models\</code>. When starting <code>Start-AI-Router.bat</code>, the console should display <code>[VISION]</code> next to the model name.
</details>

<details>
<summary><b>The model generates slowly.</b></summary>
1. Plug your USB drive into a high-speed USB 3.0 / 3.2 port (blue or red port, or USB-C).<br>
2. Close other heavy applications (browsers with many tabs, games) to free up CPU threads and RAM.<br>
3. Use <code>Q4_K_M</code> or <code>Q3_K_M</code> quantizations instead of unquantized or 8-bit models.
</details>

<details>
<summary><b>Can I use GPU acceleration if the host PC has a GPU?</b></summary>
Yes! The default installer downloads the CPU build for 100% universal compatibility across every Windows machine without requiring driver installs. If you have an NVIDIA or Vulkan-compatible GPU, you can replace the contents of <code>llama-router/</code> with the <code>llama-*-bin-win-vulkan-x64.zip</code> or <code>llama-*-bin-win-cuda-x64.zip</code> build from the <a href="https://github.com/ggml-org/llama.cpp/releases">official llama.cpp releases</a>.
</details>

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
Built with [llama.cpp](https://github.com/ggml-org/llama.cpp). Models are subject to their respective creators' licenses.
