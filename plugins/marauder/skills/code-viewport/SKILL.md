---
name: Code Viewport
description: |
  Render syntax-highlighted code on the MARAUDER visor viewport panel. Supports Ruby, Python, JavaScript, Rust, and shell.

  <example>
  Context: User wants to show code on the HUD
  user: "show this code on the hud"
  </example>

  <example>
  Context: BT wants to display a code snippet visually
  user: "render that function on the viewport"
  </example>
---

# Code Viewport

Use the `visor_code` MCP tool directly:

```
visor_code(code: "fn main() {}", language: "rust", title: "main.rs")
```

## Parameters

| Param | Description |
|-------|-------------|
| `code` | Code content to display |
| `language` | Language for syntax highlighting (e.g. `rust`, `python`, `ruby`) |
| `title` | Title shown above the code block |
| `line_numbers` | Show line numbers (default: true) |
| `start_line` | Starting line number |
| `highlight` | Line numbers to highlight |
