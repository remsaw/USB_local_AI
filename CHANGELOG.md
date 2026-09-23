# Changelog

## v1.2.0
- **Persistent Chat Attachments & Images on USB**: All uploaded images (PNG, JPG, WebP, SVG, HEIC), documents (PDF, TXT), audio, and video files are extracted and saved directly to `Data\uploads\` on the USB drive.
- **Cross-Device Availability**: Moving the USB drive to any computer automatically restores chat history along with all image attachments and previews in the Web UI.
- **Fixed History Server Hanging Bug**: Re-engineered socket reading in `Portable-History-Server.ps1` to prevent `StreamReader` buffer deadlocks on POST requests.
- **Added `/clear` and `/uploads` Server Routes**: Supports full chat history wipe (both browser IndexedDB and USB files) and direct file serving.
- **Smart Non-Thrashing Sync**: Eliminated 5-second aggressive full disk writes; syncs smartly on changes, on demand, and on launch.
- **Clean Process Lifecycle**: `Start-AI-Router.bat` terminates any stale background listeners on port 8765 before launch and cleanly shuts down on exit.
- **Git Protection**: Added `Data/conversations.json` and `Data/uploads/*` to `.gitignore`.

## v1.1.0
- Portable History retained.
- Added Clear Chat History with confirmation.
- Clears both portable history and the local browser conversation stores.
- Local-only; no cloud storage is used.
