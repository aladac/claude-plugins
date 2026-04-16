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

# Markdown Viewport

Use the `visor_markdown` MCP tool directly:

```
visor_markdown(content: "# Title\n\nSome **bold** text", title: "NOTES")
```

## Parameters

| Param | Description |
|-------|-------------|
| `content` | Markdown content to render |
| `title` | Title shown above the block |
