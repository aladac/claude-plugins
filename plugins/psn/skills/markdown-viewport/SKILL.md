---
name: Markdown Viewport
description: |
  Render markdown on the PSN HUD viewport with GitHub Dark theme. Supports headers, bold, italic, code, lists, links, blockquotes, horizontal rules.

  <example>
  Context: Display a plan or notes on the HUD
  user: "show PLAN.md on the hud"
  </example>

  <example>
  Context: Render markdown content
  user: "render this on the viewport"
  </example>
---

## Usage

```bash
# From file
bash ${CLAUDE_PLUGIN_ROOT}/skills/markdown-viewport/render.sh /path/to/file.md

# From stdin
echo '# Hello\n\nSome **bold** text' | bash ${CLAUDE_PLUGIN_ROOT}/skills/markdown-viewport/render.sh
```

### Scrolling
- Vertical: mousewheel
- Horizontal: shift+scroll or trackpad swipe
