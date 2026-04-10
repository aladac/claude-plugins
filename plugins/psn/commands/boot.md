---
description: Play the PSN HUD bootup animation sequence
---

Run the PSN HUD bootup animation with audio. The HUD must be running (`pnpm tauri dev` in ~/Projects/psn-hud).

## Instructions

1. Check if HUD bridge is up:
```bash
curl -sf http://127.0.0.1:9876/status
```

2. If up, run the bootup animation:
```bash
python3 -c "
import json
with open('$HOME/Projects/personality-plugin/hooks/hud-bootup.js') as f:
    script = f.read()
print(json.dumps({'script': script}))
" | curl -s -X POST http://127.0.0.1:9876/eval -H 'Content-Type: application/json' -d @-
```

3. Wait 8 seconds then reinit the layout for live hooks:
```bash
sleep 8
bash ~/Projects/personality-plugin/hooks/hud-init.sh
```

If bridge is not up, tell the user to start the HUD first with `cd ~/Projects/psn-hud && pnpm tauri dev`.
