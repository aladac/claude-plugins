---
description: Generate multiple AI images and display as grid on HUD
---

Generate multiple images from the same prompt and display as a grid on the HUD.

## Instructions

1. Take the user's prompt from $ARGUMENTS. Default count is 4.

2. Parse count if specified (e.g., "4 mech designs" → count=4, prompt="mech designs").

3. Generate the batch:
```bash
bash ~/Projects/personality-plugin/skills/tsr/tsr.sh batch "$PROMPT" --count $COUNT --hud --columns $COLS --title "BATCH"
```

4. Choose columns based on count:
   - 2-3 images: 2 columns
   - 4 images: 2 columns
   - 6 images: 3 columns
   - 9 images: 3 columns

5. After generation, report how many succeeded and show the grid on HUD.

## Examples

- `/tsr:batch 4 robot designs` → 4 images, 2x2 grid
- `/tsr:batch 9 landscape scenes` → 9 images, 3x3 grid
- `/tsr:batch 6 portraits --model dreamshaper` → 6 images with specific model
