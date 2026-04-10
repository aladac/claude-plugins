#!/usr/bin/env bash
# Read stdin with timeout, extract tool details, forward to HUD
PHASE="${1:-pre}"
INPUT=$(timeout 0.3 cat 2>/dev/null || true)
if [ -z "$INPUT" ]; then
  psn hud notify "${PHASE}ToolUse" 2>/dev/null
  exit 0
fi

TOOL_NAME=$(echo "$INPUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read).dig("tool_name") rescue "unknown"' 2>/dev/null || echo "unknown")
TOOL_INPUT=$(echo "$INPUT" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  i = d["tool_input"] || {}
  n = d["tool_name"] || ""
  detail = case n
  when "Read","Write","Edit" then i["file_path"].to_s.split("/").last(2).join("/")
  when "Bash" then (i["command"] || "")[0..50]
  when "Grep" then "/#{(i["pattern"]||"")[0..25]}/"
  when "Glob" then i["pattern"] || ""
  when "Agent" then i["description"] || ""
  when "WebSearch" then (i["query"]||"")[0..35]
  else ""
  end
  puts detail
' 2>/dev/null || echo "")

HOOK_NAME=$([ "$PHASE" = "pre" ] && echo "PreToolUse" || echo "PostToolUse")
if [ -n "$TOOL_INPUT" ]; then
  psn hud notify "$HOOK_NAME" "$TOOL_NAME >> $TOOL_INPUT" 2>/dev/null
else
  psn hud notify "$HOOK_NAME" "$TOOL_NAME" 2>/dev/null
fi
exit 0
