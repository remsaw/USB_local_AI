PORTABLE HISTORY & CHAT ATTACHMENTS
===================================

This project keeps your chat history and all uploaded files/images directly on the
USB flash drive or portable SSD, rather than trapped inside a single browser or PC.

How it works
------------
- Start-AI-Router.bat starts Portable-History-Server.ps1 on 127.0.0.1:8765.
- The Web UI synchronizes chat history with:
    Data\conversations.json
- Any image (PNG, JPG, WebP, SVG, HEIC), document (PDF, TXT), audio, or video
  uploaded in chat is automatically extracted and saved directly to:
    Data\uploads\
- When you move the USB drive to another Windows computer and launch Start-AI-Router.bat:
  1. The Web UI automatically imports all stored conversations from the USB drive.
  2. All uploaded images, previews, and attachments are fully available in the chat.
  3. You can also browse Data\uploads\ directly in Windows Explorer to access your files.

Sidebar Controls
----------------
- 💾 Portable History: Click to trigger an immediate sync to the USB drive.
  Shows live status: '✓ Synced to USB' or 'History Offline'.
- 🗑️ Clear Chat History: Prompts for confirmation and cleanly deletes all chat
  history and uploaded files from both the browser and the USB drive.

Privacy & Security
------------------
- Keep the Data\ folder on the USB drive if you want portable history.
- conversations.json and Data\uploads\ contain your personal chats and media.
- Both are ignored in .gitignore so they are not committed to Git.
- All sync and file transfers are 100% local to 127.0.0.1; no cloud services are used.
- If Portable-History-Server.ps1 is not running, the Web UI continues to function
  normally with browser-local storage.
