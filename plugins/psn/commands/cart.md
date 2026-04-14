---
description: Load and activate a persona with TTS and communication preferences
---

# Persona Loader

Load and activate a persona, apply communication preferences, and report system status.

## Step 1: Gather everything via CLI

Run a **single Bash call** that collects all data at once:

```bash
TAG="${ARGUMENTS:-$(grep -A1 '^\[tts\]' ~/.config/psn/config.toml 2>/dev/null | grep voice | cut -d'"' -f2)}"
echo "===HOST==="; hostname; uname -s
echo "===CARTS==="; marauder cart list 2>/dev/null
echo "===SHOW==="; marauder cart show "${TAG:-bt7274}" 2>/dev/null
echo "===TTS==="; marauder tts current 2>/dev/null
echo "===PREFS==="; marauder memory recall "TTS voice communication preferences" 2>/dev/null
```

This gives you: host/OS, available carts, cart details, TTS status, and communication preferences — all in one output.

## Step 2: Activate and report

- If the TAG from step 1 matched a valid cart, call `cart_use` with that tag
- If $ARGUMENTS didn't match any cart, present choices via `AskUserQuestion`
- Apply recalled TTS and communication preferences
- Display status (text only, no TTS):

```
Host -> {hostname} ({os})
Persona -> {name} ({tag})
TTS -> {status}
Communication -> Applied
```
