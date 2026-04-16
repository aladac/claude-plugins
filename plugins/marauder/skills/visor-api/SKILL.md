---
name: visor-api
description: "MARAUDER VISOR HTTP API reference — endpoints, payloads, and display commands on port 9876"
---

# MARAUDER VISOR HTTP API

The visor is a Ratatui TUI with an axum HTTP bridge at `http://127.0.0.1:9876`. Use it when visual output adds value.

## Quick Start

```bash
# Check if visor is running (silent fail if not)
curl -sf http://127.0.0.1:9876/status >/dev/null 2>&1

# Display an image (file path, base64, or https)
curl -s -X POST http://127.0.0.1:9876/image -H 'Content-Type: application/json' \
  -d '{"source": "file:///tmp/image.png", "title": "TITLE", "caption": "description"}'

# Display code with syntax highlighting
curl -s -X POST http://127.0.0.1:9876/code -H 'Content-Type: application/json' \
  -d '{"code": "fn main() {}", "language": "rust", "title": "main.rs"}'

# Append to activity log
curl -s -X POST http://127.0.0.1:9876/log -H 'Content-Type: application/json' \
  -d '{"segments": [{"text": "Status", "color": "#00ff88", "bold": true}, {"text": " updated", "color": "#e0e0e0"}]}'

# Clear the viewport
curl -s -X POST http://127.0.0.1:9876/viewport/clear -H 'Content-Type: application/json'
```

## Code Display

When presenting code snippets in chat, also render them on the visor viewport via `POST /code`. Syntect handles server-side highlighting.

```json
{
  "code": "pub struct BridgeState {\n    pub port: u16,\n}",
  "language": "rust",
  "title": "bridge.rs",
  "line_numbers": true,
  "start_line": 1,
  "highlight": [2]
}
```

## Image Display

Use `POST /image` for single images and `POST /image/grid` for galleries.

```json
// POST /image
{"source": "file:///path/to/img.png", "title": "TITLE", "caption": "desc", "classification": "[ GENERATED ]", "tint": true}

// POST /image/grid
{"images": [{"source": "file:///path.png", "caption": "img1"}], "title": "GALLERY", "columns": 3, "tint": true}
```

## When to Use

- Status dashboards (job pipeline, build results, scan summaries)
- Notifications (agent completions, email alerts)
- Code snippets (key excerpts when discussing code in chat)
- Generated images (AI art, screenshots, diagrams)
- Casual (greetings, fun stuff — treat it like a living display)

## When NOT to Use

- If bridge is down — check first, skip silently if unavailable
- Don't block on visor output — it's fire-and-forget
- Don't use visor *instead* of text responses — it supplements, not replaces

## Full API Reference

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/status` | GET | Check visor status |
| `/state` | GET | Read-only visor state snapshot |
| `/image` | POST | Display image in viewport |
| `/image/grid` | POST | Display image grid in viewport |
| `/code` | POST | Display syntax-highlighted code |
| `/log` | POST | Append to activity log |
| `/log/clear` | POST | Clear activity log |
| `/mood` | POST | Set SERE eye mood |
| `/field` | POST | Set identity panel field |
| `/avatar` | POST | Set avatar state |
| `/status-bar` | POST | Update status bar |
| `/dossier` | POST | Set dossier display |
| `/boot` | POST | Trigger boot animation |
| `/viewport/clear` | POST | Clear viewport |
| `/session/end` | POST | End session |
