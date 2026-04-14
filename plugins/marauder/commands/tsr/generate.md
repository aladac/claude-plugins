---
description: Generate an AI image and display on HUD
---

Generate an image using ComfyUI on junkpile via tsr. Always display on the HUD.

## Instructions

1. Take the user's prompt from $ARGUMENTS. If empty, ask what they want to generate.

2. Generate the image:
```bash
bash ~/Projects/marauder-plugin/skills/tsr/tsr.sh generate "$PROMPT" --hud --title "GENERATED" --caption "$PROMPT"
```

3. After generation, read the output image with the Read tool to show it to the user.

4. If the user specifies a model, add `--model <name>`. If they want specific dimensions, add `--width W --height H`. If they want more steps, add `--steps N`.

## Examples

- `/tsr:generate a mech in a cyberpunk city` → generates and displays on HUD
- `/tsr:generate portrait photo --model dreamshaper` → uses specific model
- `/tsr:generate landscape --steps 30` → more sampling steps
