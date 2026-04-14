---
name: Preview
description: |
  Render an HTML file or live URL as a screenshot on the PSN HUD visor viewport.
  Use for component mockups, website snapshots, and visual previews.

  <example>
  Context: User wants to preview a component mockup
  user: "show this mockup on the visor"
  </example>

  <example>
  Context: Check a live website visually
  user: "screenshot kwit.fit and show on visor"
  </example>

  <example>
  Context: Preview a design before implementing
  user: "render this HTML and display on viewport"
  </example>
---

## Usage

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/preview/preview.py <file_or_url> [options]
```

### HTML file preview
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/preview/preview.py /tmp/mockup.html --title "MOCKUP"
```

### Live website screenshot
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/preview/preview.py https://kwit.fit --title "KWIT.FIT" --full-page
```

### Custom viewport (mobile)
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/preview/preview.py https://example.com --width 390 --height 844 --title "MOBILE"
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--title` | filename/domain | Visor title |
| `--caption` | none | Visor caption |
| `--width` | 640 | Viewport width |
| `--height` | 400 | Viewport height |
| `--full-page` | false | Capture full scrollable page |
| `--no-visor` | false | Save screenshot only |
| `--output` | /tmp/preview.png | Screenshot output path |
| `--delay` | 1000 | Wait before capture (ms) |

### Workflow

1. Write HTML to a temp file (or use a URL directly)
2. Run the preview script — it handles browser, screenshot, and visor display in one call
3. The screenshot path is printed to stdout for reading with the Read tool if needed

### Prerequisites

- Playwright (`pip install playwright && playwright install chromium`)
- Visor running on port 9876 (optional — use `--no-visor` without it)
