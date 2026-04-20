---
name: Image Generation
description: |
  Generate AI images via ComfyUI on junkpile using the tsr CLI. Supports text-to-image with model/LoRA selection, and displays results on the MARAUDER visor viewport.

  <example>
  Context: User wants to generate an image
  user: "generate a mech in a city"
  </example>

  <example>
  Context: User wants a specific style
  user: "generate a portrait photo, use dreamshaper"
  </example>

  <example>
  Context: User wants multiple images
  user: "generate 4 images of cyberpunk scenes"
  </example>

  <example>
  Context: User wants to see available models
  user: "what models do we have?"
  </example>

  <example>
  Context: User wants to show an image on the HUD
  user: "show that on the hud"
  </example>

  <example>
  Context: User wants a grid of images
  user: "generate a grid of robot designs"
  </example>
version: 1.0.0
---

# Image Generation Skill

Generate AI images using ComfyUI on junkpile via the `tsr` CLI and display results on the MARAUDER visor.

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/tsr/tsr.sh"

# Generate an image (default: SDXL, 1024x1024, 20 steps)
bash $SKILL generate "a giant mech robot in fog"

# Generate with options
bash $SKILL generate "portrait photo" --model dreamshaper --steps 30

# Generate and display on HUD
bash $SKILL generate "cyberpunk city at night" --hud

# Generate multiple images
bash $SKILL batch "robot designs" --count 4

# Generate and display as grid on HUD
bash $SKILL batch "landscape scenes" --count 9 --hud --columns 3

# Display an existing image on HUD
bash $SKILL hud /tmp/image.png
bash $SKILL hud /tmp/image.png --title "RECON" --caption "Target acquired"

# Display multiple images as grid on HUD
bash $SKILL grid /tmp/img1.png /tmp/img2.png /tmp/img3.png

# List available models
bash $SKILL models

# Check ComfyUI status
bash $SKILL status
```

## Commands

| Command | Description |
|---------|-------------|
| `generate <prompt> [opts]` | Generate a single image |
| `batch <prompt> [opts]` | Generate multiple images |
| `hud <file> [opts]` | Display image on HUD viewport |
| `grid <files...> [opts]` | Display image grid on HUD viewport |
| `models` | List available checkpoint models |
| `status` | Check ComfyUI/tensors API status |

## Generate Options

| Flag | Default | Description |
|------|---------|-------------|
| `--model`, `-m` | (SDXL default) | Checkpoint model name |
| `--steps` | 20 | Sampling steps |
| `--width`, `-W` | 1024 | Image width |
| `--height`, `-H` | 1024 | Image height |
| `--cfg` | 7.0 | CFG scale |
| `--seed`, `-s` | -1 (random) | Random seed |
| `--negative`, `-n` | (auto) | Negative prompt |
| `--lora`, `-l` | (none) | LoRA model name |
| `--output`, `-o` | /tmp/tsr-*.png | Output path |
| `--hud` | false | Display result on HUD viewport |
| `--title` | "GENERATED" | HUD display title |
| `--caption` | (prompt text) | HUD display caption |

## Batch Options

All generate options plus:

| Flag | Default | Description |
|------|---------|-------------|
| `--count`, `-c` | 4 | Number of images to generate |
| `--columns` | auto | Grid columns when --hud is used |

## HUD Display Options

| Flag | Default | Description |
|------|---------|-------------|
| `--title` | "IMAGE" | Header title text |
| `--caption` | (filename) | Caption below image |
| `--classification` | "[ GENERATED ]" | Right-aligned tag |
| `--no-tint` | false | Disable green tint |

## Infrastructure

- **ComfyUI**: Running on junkpile (10.0.0.2), RTX 2000 Ada GPU
- **tensors API**: Port 5003 on junkpile
- **tsr CLI**: `/Users/chi/.local/bin/tsr`
- **Remote flag**: `--remote junkpile` (always used, generation runs on GPU)
- **HUD bridge**: http://127.0.0.1:9876 (MARAUDER visor eval endpoint)

## Default Negative Prompt

When no `--negative` is provided, the skill appends:
`blurry, low quality, text, watermark, deformed, ugly`

## Models (as of 2026-04-10)

Run `bash $SKILL models` for current list. Known checkpoints:
- SDXL base (default)
- DreamShaper 8 (SD 1.5)
- Super Robot Diffusion Rise (mecha)
- MechaDream (mecha)

## Prerequisites

- `tsr` CLI installed (`/Users/chi/.local/bin/tsr`)
- ComfyUI running on junkpile
- MARAUDER visor running (for --hud display)
- junkpile reachable at 10.0.0.2
