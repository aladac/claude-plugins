#!/usr/bin/env bash
# PSN HUD — Code Specialist Loadout Display
# Draws weapon cards for each code-specialist agent with staggered animation
# Usage: bash loadout.sh
set -euo pipefail

HUD="http://127.0.0.1:9876"

if ! curl -sf "$HUD/status" >/dev/null 2>&1; then
  echo "HUD not running" >&2
  exit 1
fi

JS_FILE=$(mktemp /tmp/psn-loadout-XXXXXX.js)
trap "rm -f $JS_FILE" EXIT

cat > "$JS_FILE" <<'JS'
(function() {
  const c = window.PSN.canvas;
  const W = c.canvas.width;
  const H = c.canvas.height;

  const GREEN = "#00ff88";
  const DIM = "#00ff8844";
  const BG = "#1d232a";
  const BORDER_W = 3;

  // Right panel (viewport) — mirrors getLayout()
  const pad = 20;
  const avBoxW = 120;
  const avX = Math.floor(W / 2);
  const vpLeft = avX + avBoxW / 2 + 5;
  const vpW = W - vpLeft - pad;
  const vpTop = pad;
  const vpH = H - 110 - pad;

  // Card layout
  const cols = 2;
  const gap = 14;
  const innerPad = 16;
  const cardW = Math.floor((vpW - innerPad * 2 - gap) / cols);
  const cardH = Math.floor(cardW * 0.48);
  const vpCx = vpLeft + vpW / 2;

  /* weapons + layout defined at bottom after all functions */
  function run(weapons) {
  var rows = Math.ceil(weapons.length / cols);
  var totalH = rows * cardH + (rows - 1) * gap + 50;
  var startX = vpLeft + innerPad;
  var startY = vpTop + (vpH - totalH) / 2 + 30;
  const positions = weapons.map((w, i) => {
    const row = Math.floor(i / cols);
    const col = i % cols;
    const lastRow = Math.floor((weapons.length - 1) / cols);
    const rowItems = (row === lastRow && weapons.length % cols !== 0) ? weapons.length % cols : cols;
    const rowOffsetX = (rowItems < cols) ? (cardW + gap) / 2 : 0;
    return {
      x: startX + col * (cardW + gap) + rowOffsetX,
      y: startY + row * (cardH + gap)
    };
  });

  // Clear viewport
  c.fillStyle = BG;
  c.fillRect(vpLeft, vpTop, vpW, vpH);

  // Animation state
  const CARD_DELAY = 300;   // ms between each card
  const FADE_DURATION = 300; // ms per card fade-in
  const animStart = Date.now();
  let titleDrawn = false;
  let statusDrawn = false;
  let done = false;

  function frame() {
    if (done) return;
    const now = Date.now();
    const elapsed = now - animStart;

    // Title fades in first (0-300ms)
    if (!titleDrawn) {
      const titleAlpha = Math.min(1, elapsed / 300);
      c.save();
      c.globalAlpha = titleAlpha;
      c.font = "bold 22px monospace";
      c.fillStyle = GREEN;
      c.textAlign = "center";
      c.fillText("LOADOUT \u2014 CODE SPECIALISTS", vpCx, startY - 35);
      c.font = "12px monospace";
      c.fillStyle = DIM.replace("44", Math.floor(titleAlpha * 0x44).toString(16).padStart(2, "0"));
      c.fillText("WEAPONS SYSTEMS ONLINE", vpCx, startY - 16);
      c.restore();
      if (titleAlpha >= 1) titleDrawn = true;
    }

    // Each card appears staggered
    let allDone = true;
    weapons.forEach((w, i) => {
      const cardStart = 300 + i * CARD_DELAY;
      const cardElapsed = elapsed - cardStart;
      if (cardElapsed <= 0) { allDone = false; return; }

      const alpha = Math.min(1, cardElapsed / FADE_DURATION);
      if (alpha < 1) allDone = false;

      // Clear card area each frame to prevent stacking
      const p = positions[i];
      c.fillStyle = BG;
      c.fillRect(p.x - 1, p.y - 1, cardW + 2, cardH + 25);

      c.save();
      c.globalAlpha = alpha;
      drawCard(c, p.x, p.y, cardW, cardH, w, GREEN, DIM, BG, BORDER_W);
      c.restore();
    });

    // Status line after all cards
    if (allDone && !statusDrawn) {
      const lastRow = Math.floor((weapons.length - 1) / cols);
      const statusY = startY + (lastRow + 1) * (cardH + gap) + 10;
      c.font = "11px monospace";
      c.fillStyle = DIM;
      c.textAlign = "center";
      c.fillText(weapons.length + " WEAPONS LOADED  //  PILOT AUTHORIZATION REQUIRED", vpCx, statusY);
      c.textAlign = "left";
      statusDrawn = true;
      done = true;
      return;
    }

    requestAnimationFrame(frame);
  }

  requestAnimationFrame(frame);

  // ── Card Renderer ──

  function drawCard(c, x, y, w, h, weapon, green, dim, bg, bw) {
    c.strokeStyle = green;
    c.lineWidth = bw;
    c.strokeRect(x, y, w, h);

    // Scanlines
    c.save();
    c.globalAlpha = c.globalAlpha * 0.03;
    for (let sy = y; sy < y + h; sy += 3) {
      c.fillStyle = green;
      c.fillRect(x + 1, sy, w - 2, 1);
    }
    c.restore();

    // Corner brackets
    const cb = 12;
    c.strokeStyle = green;
    c.lineWidth = 2;
    c.beginPath(); c.moveTo(x + cb, y); c.lineTo(x, y); c.lineTo(x, y + cb); c.stroke();
    c.beginPath(); c.moveTo(x + w - cb, y); c.lineTo(x + w, y); c.lineTo(x + w, y + cb); c.stroke();
    c.beginPath(); c.moveTo(x, y + h - cb); c.lineTo(x, y + h); c.lineTo(x + cb, y + h); c.stroke();
    c.beginPath(); c.moveTo(x + w, y + h - cb); c.lineTo(x + w, y + h); c.lineTo(x + w - cb, y + h); c.stroke();

    // Layout zones
    const symCx = x + h * 0.5;
    const symCy = y + h * 0.48;
    const infoCx = x + h + (w - h) / 2;

    // Divider
    c.strokeStyle = dim;
    c.lineWidth = 1;
    c.beginPath(); c.moveTo(x + h, y + 12); c.lineTo(x + h, y + h - 12); c.stroke();

    // Symbol
    weapon.draw(c, symCx, symCy, green, dim);

    // Name
    c.font = "bold 26px monospace";
    c.fillStyle = green;
    c.textAlign = "center";
    c.fillText(weapon.name, infoCx, y + h * 0.4);

    // Designation
    c.font = "bold 16px monospace";
    c.fillStyle = dim;
    c.fillText(weapon.code, infoCx, y + h * 0.6);

    // Language icon
    weapon.icon(c, infoCx, y + h * 0.78, green);
    c.textAlign = "left";
  }

  // ── Weapon Symbols ──

  function drawKatana(c, cx, cy, green, dim) {
    c.save(); c.translate(cx, cy); c.rotate(-Math.PI / 6);
    c.strokeStyle = green; c.lineWidth = 3;
    c.beginPath(); c.moveTo(0, -55); c.lineTo(0, 30); c.stroke();
    c.strokeStyle = dim; c.lineWidth = 1;
    c.beginPath(); c.moveTo(2, -50); c.lineTo(2, 25); c.stroke();
    c.fillStyle = green;
    c.beginPath(); c.moveTo(-2, -55); c.lineTo(0, -62); c.lineTo(2, -55); c.fill();
    c.strokeStyle = green; c.lineWidth = 3;
    c.beginPath(); c.moveTo(-14, 30); c.lineTo(14, 30); c.stroke();
    c.lineWidth = 2;
    for (let i = 0; i < 4; i++) {
      const gy = 36 + i * 7;
      c.beginPath(); c.moveTo(-4, gy); c.lineTo(4, gy); c.stroke();
    }
    c.restore();
  }

  function drawRailgun(c, cx, cy, green, dim) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 4;
    c.beginPath(); c.moveTo(-18, -45); c.lineTo(-18, 40); c.stroke();
    c.beginPath(); c.moveTo(18, -45); c.lineTo(18, 40); c.stroke();
    c.lineWidth = 3;
    c.beginPath(); c.moveTo(-22, -45); c.lineTo(22, -45); c.stroke();
    c.strokeStyle = green; c.lineWidth = 2;
    c.beginPath(); c.arc(0, -5, 10, 0, Math.PI * 2); c.stroke();
    c.strokeStyle = dim;
    c.beginPath(); c.arc(0, -5, 16, 0, Math.PI * 2); c.stroke();
    c.strokeStyle = dim; c.lineWidth = 1;
    for (let i = 0; i < 5; i++) {
      c.beginPath(); c.moveTo(-18, -35 + i * 18); c.lineTo(18, -35 + i * 18); c.stroke();
    }
    c.fillStyle = green; c.save(); c.globalAlpha = c.globalAlpha * 0.3;
    c.beginPath(); c.moveTo(-8, -50); c.lineTo(0, -60); c.lineTo(8, -50); c.fill();
    c.restore();
    c.restore();
  }

  function drawViper(c, cx, cy, green, dim) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 3;
    c.beginPath(); c.moveTo(-20, -35); c.quadraticCurveTo(-22, -5, -8, 30); c.stroke();
    c.beginPath(); c.moveTo(20, -35); c.quadraticCurveTo(22, -5, 8, 30); c.stroke();
    c.fillStyle = green;
    c.beginPath(); c.moveTo(-10, 25); c.lineTo(-6, 35); c.lineTo(-4, 25); c.fill();
    c.beginPath(); c.moveTo(10, 25); c.lineTo(6, 35); c.lineTo(4, 25); c.fill();
    c.fillStyle = green;
    c.beginPath(); c.ellipse(-10, -20, 6, 3, -0.3, 0, Math.PI * 2); c.fill();
    c.beginPath(); c.ellipse(10, -20, 6, 3, 0.3, 0, Math.PI * 2); c.fill();
    c.fillStyle = "#1d232a";
    c.beginPath(); c.ellipse(-10, -20, 2, 3, -0.3, 0, Math.PI * 2); c.fill();
    c.beginPath(); c.ellipse(10, -20, 2, 3, 0.3, 0, Math.PI * 2); c.fill();
    c.fillStyle = dim;
    c.beginPath(); c.moveTo(-6, 35); c.quadraticCurveTo(-5, 42, -4, 35); c.fill();
    c.beginPath(); c.moveTo(6, 35); c.quadraticCurveTo(5, 42, 4, 35); c.fill();
    c.restore();
  }

  function drawLance(c, cx, cy, green, dim) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 3;
    c.beginPath(); c.moveTo(0, -20); c.lineTo(0, 50); c.stroke();
    c.fillStyle = green;
    c.beginPath(); c.moveTo(0, -55); c.lineTo(-12, -20); c.lineTo(-3, -22); c.lineTo(-3, -20);
    c.lineTo(3, -20); c.lineTo(3, -22); c.lineTo(12, -20); c.closePath(); c.fill();
    c.strokeStyle = "#1d232a"; c.lineWidth = 1;
    c.beginPath(); c.moveTo(0, -52); c.lineTo(0, -22); c.stroke();
    c.strokeStyle = green; c.lineWidth = 2;
    c.beginPath(); c.moveTo(-16, -16); c.lineTo(0, -20); c.lineTo(16, -16); c.stroke();
    c.strokeStyle = dim; c.lineWidth = 1;
    for (let i = 0; i < 6; i++) {
      c.beginPath(); c.moveTo(-3, -10 + i * 10); c.lineTo(3, -10 + i * 10); c.stroke();
    }
    c.restore();
  }

  function drawReactor(c, cx, cy, green, dim) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 3;
    c.beginPath(); c.arc(0, 0, 35, 0, Math.PI * 2); c.stroke();
    c.strokeStyle = dim; c.lineWidth = 2;
    c.beginPath(); c.arc(0, 0, 24, 0, Math.PI * 2); c.stroke();
    c.strokeStyle = green; c.lineWidth = 2;
    c.beginPath(); c.arc(0, 0, 12, 0, Math.PI * 2); c.stroke();
    c.fillStyle = green;
    c.beginPath(); c.arc(0, 0, 4, 0, Math.PI * 2); c.fill();
    c.strokeStyle = green; c.lineWidth = 1;
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * Math.PI * 2;
      c.beginPath(); c.moveTo(Math.cos(a) * 14, Math.sin(a) * 14);
      c.lineTo(Math.cos(a) * 33, Math.sin(a) * 33); c.stroke();
    }
    c.fillStyle = green;
    for (let i = 0; i < 3; i++) {
      const a = (i / 3) * Math.PI * 2 + 0.3;
      c.beginPath(); c.arc(Math.cos(a) * 28, Math.sin(a) * 28, 3, 0, Math.PI * 2); c.fill();
    }
    c.restore();
  }

  } // end run

  // ── Weapon Symbols (must be declared before run() is called) ──

  function drawTrident(c, cx, cy, green, dim) {
    // Three-pronged trident — network forks
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 3;
    // Center shaft
    c.beginPath(); c.moveTo(0, -45); c.lineTo(0, 45); c.stroke();
    // Left prong
    c.beginPath(); c.moveTo(-18, -30); c.lineTo(-18, -45); c.stroke();
    c.beginPath(); c.moveTo(0, -25); c.lineTo(-18, -30); c.stroke();
    // Right prong
    c.beginPath(); c.moveTo(18, -30); c.lineTo(18, -45); c.stroke();
    c.beginPath(); c.moveTo(0, -25); c.lineTo(18, -30); c.stroke();
    // Tips
    c.fillStyle = green;
    c.beginPath(); c.moveTo(-2, -48); c.lineTo(0, -55); c.lineTo(2, -48); c.fill();
    c.beginPath(); c.moveTo(-20, -48); c.lineTo(-18, -55); c.lineTo(-16, -48); c.fill();
    c.beginPath(); c.moveTo(16, -48); c.lineTo(18, -55); c.lineTo(20, -48); c.fill();
    // Cross bar
    c.lineWidth = 2;
    c.beginPath(); c.moveTo(-10, 20); c.lineTo(10, 20); c.stroke();
    c.restore();
  }

  function drawFlare(c, cx, cy, green, dim) {
    // Starburst / flare — Cloudflare energy
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 2;
    // Rays (8)
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * Math.PI * 2;
      const inner = (i % 2 === 0) ? 12 : 8;
      const outer = (i % 2 === 0) ? 38 : 28;
      c.beginPath();
      c.moveTo(Math.cos(a) * inner, Math.sin(a) * inner);
      c.lineTo(Math.cos(a) * outer, Math.sin(a) * outer);
      c.stroke();
    }
    // Core
    c.fillStyle = green;
    c.beginPath(); c.arc(0, 0, 8, 0, Math.PI * 2); c.fill();
    c.fillStyle = "#1d232a";
    c.beginPath(); c.arc(0, 0, 4, 0, Math.PI * 2); c.fill();
    // Outer halo
    c.strokeStyle = dim; c.lineWidth = 1;
    c.beginPath(); c.arc(0, 0, 42, 0, Math.PI * 2); c.stroke();
    c.restore();
  }

  function drawForge(c, cx, cy, green, dim) {
    // Anvil + hammer — forge / build
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 2;
    // Anvil base
    c.fillStyle = green;
    c.beginPath();
    c.moveTo(-25, 15); c.lineTo(-20, 5); c.lineTo(20, 5); c.lineTo(25, 15);
    c.lineTo(18, 15); c.lineTo(18, 20); c.lineTo(-18, 20); c.lineTo(-18, 15);
    c.closePath(); c.stroke();
    // Anvil top surface
    c.lineWidth = 3;
    c.beginPath(); c.moveTo(-22, 5); c.lineTo(22, 5); c.stroke();
    // Hammer (diagonal)
    c.lineWidth = 2;
    c.beginPath(); c.moveTo(5, -5); c.lineTo(20, -40); c.stroke();
    // Hammer head
    c.fillStyle = green;
    c.save(); c.translate(20, -40); c.rotate(-0.3);
    c.fillRect(-12, -5, 24, 10);
    c.restore();
    // Spark
    c.fillStyle = dim;
    c.beginPath(); c.arc(-8, -2, 2, 0, Math.PI * 2); c.fill();
    c.beginPath(); c.arc(-14, -8, 1.5, 0, Math.PI * 2); c.fill();
    c.beginPath(); c.arc(-5, -12, 1, 0, Math.PI * 2); c.fill();
    c.restore();
  }

  // ── Language/Tool Icons (canvas-drawn, small ~20px) ──

  function drawRubyIcon(c, cx, cy, green) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 1.5;
    c.beginPath(); c.moveTo(0,-9); c.lineTo(8,-2); c.lineTo(0,9); c.lineTo(-8,-2); c.closePath(); c.stroke();
    c.beginPath(); c.moveTo(-8,-2); c.lineTo(8,-2); c.stroke();
    c.beginPath(); c.moveTo(-4,-2); c.lineTo(0,9); c.stroke();
    c.beginPath(); c.moveTo(4,-2); c.lineTo(0,9); c.stroke();
    c.restore();
  }
  function drawRustIcon(c, cx, cy, green) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 1.5;
    c.beginPath(); c.arc(0,0,7,0,Math.PI*2); c.stroke();
    for(var i=0;i<6;i++){var a=(i/6)*Math.PI*2; c.beginPath(); c.moveTo(Math.cos(a)*7,Math.sin(a)*7); c.lineTo(Math.cos(a)*11,Math.sin(a)*11); c.stroke();}
    c.fillStyle = green; c.beginPath(); c.arc(0,0,2,0,Math.PI*2); c.fill();
    c.restore();
  }
  function drawPythonIcon(c, cx, cy, green) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 2;
    c.beginPath(); c.moveTo(-6,-8); c.quadraticCurveTo(6,-8,6,0); c.stroke();
    c.beginPath(); c.moveTo(6,8); c.quadraticCurveTo(-6,8,-6,0); c.stroke();
    c.beginPath(); c.moveTo(-6,-8); c.lineTo(-6,0); c.stroke();
    c.beginPath(); c.moveTo(6,0); c.lineTo(6,8); c.stroke();
    c.fillStyle = green;
    c.beginPath(); c.arc(-3,-6,1.5,0,Math.PI*2); c.fill();
    c.beginPath(); c.arc(3,6,1.5,0,Math.PI*2); c.fill();
    c.restore();
  }
  function drawTSIcon(c, cx, cy, green) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 1.5; c.strokeRect(-10,-9,20,18);
    c.fillStyle = green; c.font = "bold 11px monospace"; c.textAlign = "center"; c.textBaseline = "middle";
    c.fillText("TS",0,1); c.textBaseline = "alphabetic"; c.restore();
  }
  function drawDioxusIcon(c, cx, cy, green) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 1.2;
    c.fillStyle = green; c.beginPath(); c.arc(0,0,2.5,0,Math.PI*2); c.fill();
    for(var i=0;i<3;i++){c.save(); c.rotate((i/3)*Math.PI); c.beginPath(); c.ellipse(0,0,10,5,0,0,Math.PI*2); c.stroke(); c.restore();}
    c.restore();
  }
  function drawNetIcon(c, cx, cy, green) {
    c.save(); c.translate(cx, cy);
    c.fillStyle = green;
    c.beginPath(); c.arc(0,-8,3,0,Math.PI*2); c.fill();
    c.beginPath(); c.arc(-8,7,3,0,Math.PI*2); c.fill();
    c.beginPath(); c.arc(8,7,3,0,Math.PI*2); c.fill();
    c.strokeStyle = green; c.lineWidth = 1.5;
    c.beginPath(); c.moveTo(0,-5); c.lineTo(-8,4); c.stroke();
    c.beginPath(); c.moveTo(0,-5); c.lineTo(8,4); c.stroke();
    c.beginPath(); c.moveTo(-5,7); c.lineTo(5,7); c.stroke();
    c.restore();
  }
  function drawCFIcon(c, cx, cy, green) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 1.5;
    c.beginPath(); c.arc(3,-2,8,Math.PI*0.8,Math.PI*2.2); c.stroke();
    c.beginPath(); c.arc(-5,2,6,Math.PI*0.9,Math.PI*2.1); c.stroke();
    c.beginPath(); c.moveTo(-11,8); c.lineTo(11,8); c.stroke();
    c.restore();
  }
  function drawGHIcon(c, cx, cy, green) {
    c.save(); c.translate(cx, cy);
    c.strokeStyle = green; c.lineWidth = 1.5;
    c.beginPath(); c.arc(0,-1,9,0,Math.PI*2); c.stroke();
    c.fillStyle = green;
    c.beginPath(); c.arc(-3,-3,1.5,0,Math.PI*2); c.fill();
    c.beginPath(); c.arc(3,-3,1.5,0,Math.PI*2); c.fill();
    c.beginPath(); c.moveTo(-4,3); c.quadraticCurveTo(0,6,4,3); c.stroke();
    c.restore();
  }

  // ── Weapons Array (after all function declarations) ──

  var weapons = [
    { name: "KATANA",  code: "RB-34",  agent: "code-ruby",       draw: drawKatana,   icon: drawRubyIcon },
    { name: "RAILGUN", code: "RS-94",  agent: "code-rust",       draw: drawRailgun,  icon: drawRustIcon },
    { name: "VIPER",   code: "PY-312", agent: "code-python",     draw: drawViper,    icon: drawPythonIcon },
    { name: "LANCE",   code: "TS-58",  agent: "code-typescript", draw: drawLance,    icon: drawTSIcon },
    { name: "REACTOR", code: "DX-06",  agent: "code-dx",         draw: drawReactor,  icon: drawDioxusIcon },
    { name: "TRIDENT", code: "NET-88", agent: "devops-net",      draw: drawTrident,  icon: drawNetIcon },
    { name: "FLARE",   code: "CF-01",  agent: "devops-cf",       draw: drawFlare,    icon: drawCFIcon },
    { name: "FORGE",   code: "GH-10",  agent: "devops-gh",       draw: drawForge,    icon: drawGHIcon },
  ];
  run(weapons);

})();
JS

# TODO: Phase 5 — port loadout animation to ratatui Canvas widget
# For now, the JS file exists but eval endpoint is gone. Log and skip.
echo "Loadout display deferred — marauder-visor Phase 5 (ratatui Canvas port)"
curl -s -X POST "$HUD/log" -H 'Content-Type: application/json' \
  -d '{"segments":[{"text":"Loadout","color":"#ffaa00","bold":true},{"text":"  display deferred to Phase 5","color":"#668877"}]}' >/dev/null 2>&1

echo "Loadout logged"
