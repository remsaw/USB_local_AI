# USB Local AI Web UI Customizations

## MCP Servers
- Keeps the native **MCP Servers** navigation intact.
- Provides a fallback MCP sidebar link only if the native item is not present.

## Model Refresh
- Adds **↻ Refresh Models** to the model selector.
- Calls `GET /models?reload=1` so the llama.cpp router rescans the configured model source.

## Portable History & Chat Attachments
- Adds a **💾 Portable History** sidebar control: click to sync on demand, or let smart sync run in the background.
- Adds a **🗑️ Clear Chat History** button: deletes all conversations and uploaded media from both the browser and the USB drive with confirmation.
- When `Portable-History-Server.ps1` is running:
  - Chat conversations are synchronized to `Data\conversations.json` on the USB drive.
  - All uploaded images (PNG, JPG, WebP, SVG, HEIC), documents (PDF, TXT), audio, and video files are extracted and saved directly to `Data\uploads\` on the USB drive.
  - The Web UI uses the browser's `LlamaUi` IndexedDB as its local working database and keeps it seamlessly synchronized with the USB drive.
  - On another compatible Windows computer, starting `Start-AI-Router.bat` pulls stored conversations and attachments into that browser automatically.
  - Sync is local to `127.0.0.1:8765`; no cloud service is used.
  - If the portable history service is unavailable, the Web UI continues to work with browser-local history.

> **Privacy:** `Data\conversations.json` and `Data\uploads\` contain private conversations and files. They are excluded via `.gitignore` and should never be committed to a public GitHub repository.
