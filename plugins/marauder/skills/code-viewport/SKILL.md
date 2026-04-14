---
name: Code Viewport
description: |
  Render syntax-highlighted code on the PSN HUD viewport panel. Supports Ruby, Python, JavaScript, Rust, and shell.

  <example>
  Context: User wants to show code on the HUD
  user: "show this code on the hud"
  </example>

  <example>
  Context: BT wants to display a code snippet visually
  user: "render that function on the viewport"
  </example>
---

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/code-viewport/render.sh <language> <file_or_stdin>
```

Or pipe code directly:
```bash
echo 'def hello; puts "world"; end' | bash ${CLAUDE_PLUGIN_ROOT}/skills/code-viewport/render.sh ruby
```

### Supported Languages
ruby, python, javascript, rust, bash, shell, typescript

### From a file
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/code-viewport/render.sh ruby /path/to/file.rb
```

### Integration
The script sends code to the visor via POST /code on port 9876. Syntect handles syntax highlighting server-side in the visor.
