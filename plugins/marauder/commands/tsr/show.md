---
description: Display an image or images on the HUD viewport
---

Display one or more images on the MARAUDER visor viewport panel.

## Instructions

1. If $ARGUMENTS contains file path(s), display them:

Single image:
```bash
bash ~/Projects/marauder-plugin/skills/tsr/tsr.sh hud "$FILE" --title "IMAGE" --caption "$CAPTION"
```

Multiple images:
```bash
bash ~/Projects/marauder-plugin/skills/tsr/tsr.sh grid $FILES --title "GALLERY" --columns $N
```

2. If $ARGUMENTS is empty, check if there are recent tsr-generated images in /tmp:
```bash
ls -t /tmp/tsr-*.png 2>/dev/null | head -9
```
Display the most recent ones as a grid.

3. Use `--no-tint` if the user asks for full color.

## Examples

- `/tsr:show /tmp/image.png` → single image on HUD
- `/tsr:show /tmp/img1.png /tmp/img2.png /tmp/img3.png` → grid
- `/tsr:show` → show most recent generated images
