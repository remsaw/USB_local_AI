# USB Local AI UI customizations v3

- MCP Servers: preserves the native llama.cpp Web UI MCP Servers navigation when the native item exists. The patch no longer intercepts the native click event.
- If a future build has no native MCP item, a fallback sidebar link is inserted before Settings.
- Refresh Models: adds a button to the model selector that calls `GET /models?reload=1` and reloads the UI so the refreshed router model list is shown.
