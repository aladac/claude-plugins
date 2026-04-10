#!/usr/bin/env bash
# HUD MOTD — draws the startup banner table on PSN HUD canvas
# Usage: hud-motd.sh
# Silently exits if HUD bridge is not running

BRIDGE="http://127.0.0.1:9876"

# Bail silently if bridge is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

post() {
  curl -s -X POST "$BRIDGE/eval" \
    -H 'Content-Type: application/json' \
    -d "{\"script\": \"$1\"}" >/dev/null 2>&1
}

# Clear and reset cursor
post "window.PSN.clear(); window.PSN._cursorY = 30;"
sleep 0.1

# Box strokes: outer rect + two dividers
post "var c=window.PSN.canvas; c.strokeStyle='#00ff88'; c.lineWidth=1; var x=50,y=20,w=500; c.strokeRect(x,y,w,310); c.beginPath(); c.moveTo(x,y+45); c.lineTo(x+w,y+45); c.stroke(); c.beginPath(); c.moveTo(x,y+210); c.lineTo(x+w,y+210); c.stroke();"

# Title
post "var c=window.PSN.canvas; c.font='bold 16px monospace'; c.fillStyle='#00ff88'; c.fillText('PSN HUD',70,50); c.font='13px monospace'; c.fillStyle='#668877'; c.fillText('Persona System Network',180,50);"

# Fields
post "var c=window.PSN.canvas; var lx=70,vx=200,ly=90,lh=30; c.font='13px monospace'; var labels=['Titan','Callsign','Pilot','Version','Uplink']; var vals=['BT-7274','Bravo Tango','Adam Ladachowski','0.1.0','Claude Opus 4.6']; var bold=[true,false,false,false,false]; for(var i=0;i<labels.length;i++){ c.fillStyle='#668877'; c.font='13px monospace'; c.fillText(labels[i],lx,ly+i*lh); c.fillStyle='#ffffff'; c.font=bold[i]?'bold 13px monospace':'13px monospace'; c.fillText(vals[i],vx,ly+i*lh); }"

# Quote
post "var c=window.PSN.canvas; c.font='italic 13px monospace'; c.fillStyle='#00ff88'; c.fillText('\"Trust me.\"',70,260); c.font='13px monospace'; c.fillStyle='#668877'; c.fillText('\u2014 BT-7274',420,290);"

# Set cursor below box for terminal output
post "window.PSN._cursorY = 355;"

exit 0
