# Models Directory Structure

This folder holds all GGUF models that your portable local AI environment can run.

## Recommended Folder Layout

### 1. Text & Reasoning Models (DeepSeek-R1, Qwen, Llama, Mistral)
For standalone text or reasoning models, simply drop the `.gguf` file directly into this folder:
```
Models\
├── DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf
├── qwen3-4b-thinking-2507.Q4_K_M.gguf
└── Qwen3-14B-GPT-5.2-High-Reasoning-Distill.q3_k_m.gguf
```

### 2. Vision Models (Multimodal VLMs - Image Upload Enabled)
Vision models require **two files**:
1. The base model file (e.g. `Qwen2.5-VL-7B-Instruct-Q4_K_M.gguf`)
2. The matching multimodal projector file (e.g. `mmproj-Qwen2.5-VL-7B-Instruct-F16.gguf`)

To enable image uploads in the Web UI, place both files together inside a dedicated subfolder:
```
Models\
└── Qwen3VL-4B-Instruct\
    ├── Qwen3VL-4B-Instruct-Q4_K_M.gguf
    └── mmproj-Qwen3VL-4B-Instruct-F16.gguf
```

> [!TIP]
> When `Start-AI.bat` launches, it automatically detects any folder containing both a model and an `mmproj` projector, registers it with image upload capabilities, and displays the paperclip/attachment icon in the Web UI!

## Where to Download Models
Search for GGUF quantizations on [Hugging Face](https://huggingface.co/models?search=gguf):
- **Vision Models**: Search for `Qwen2.5-VL GGUF`, `Gemma-3 GGUF`, or `LLaVA GGUF`. Always download both the model and the `mmproj` projector!
- **Reasoning Models**: Search for `DeepSeek-R1-Distill GGUF` or `Qwen Thinking GGUF`.
- **General / Coding Models**: Search for `Qwen2.5-Coder GGUF` or `Llama-3.2 GGUF`.
