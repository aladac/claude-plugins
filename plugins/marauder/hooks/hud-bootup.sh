#!/usr/bin/env bash
# HUD bootup sequence — triggers boot animation on marauder-visor
BRIDGE="http://127.0.0.1:9876"

curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

curl -s -X POST "$BRIDGE/boot" \
  -H 'Content-Type: application/json' \
  -d '{}' >/dev/null 2>&1

exit 0
