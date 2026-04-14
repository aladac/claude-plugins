#!/usr/bin/env bash
# Render syntax-highlighted code on the marauder-visor viewport
# Usage: render.sh <language> [file]
# Or:    echo 'code' | render.sh <language>

set -euo pipefail

BRIDGE="http://127.0.0.1:9876"
LANG="${1:-ruby}"
FILE="${2:-}"

# Bail if HUD is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || { echo "HUD not available"; exit 1; }

# Read code from file or stdin
if [ -n "$FILE" ] && [ -f "$FILE" ]; then
    CODE=$(cat "$FILE")
    TITLE="$FILE"
else
    CODE=$(cat)
    TITLE="stdin"
fi

# Send to visor — syntect handles highlighting server-side
python3 -c "
import json, sys, urllib.request

code = '''$CODE'''
payload = json.dumps({
    'code': code,
    'language': '$LANG',
    'title': '$TITLE',
    'line_numbers': True,
    'start_line': 1,
    'highlight': []
})

req = urllib.request.Request('$BRIDGE/code', data=payload.encode(), headers={'Content-Type': 'application/json'})
urllib.request.urlopen(req)
lines = code.strip().count(chr(10)) + 1
print(f'Rendered {lines} lines of $LANG on visor')
"
