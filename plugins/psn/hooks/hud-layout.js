var c = window.PSN.canvas; var cv = c.canvas; var W = cv.width; var H = cv.height; var pad = 20; var midX = Math.floor(W * 0.45); var botY = H - 50;

// Clear
c.fillStyle = "#1d232a"; c.fillRect(0, 0, W, H);

// === AVATAR BOX — top center, compact ===
var avSize = 50;
var avBoxW = 80; var avBoxH = 80;
var avX = Math.floor(W / 2); var avBoxLeft = avX - avBoxW/2; var avBoxTop = pad;
c.strokeStyle = "#00ff88"; c.lineWidth = 1;
c.strokeRect(avBoxLeft, avBoxTop, avBoxW, avBoxH);
// Corner accents
var accent = 12; c.lineWidth = 2;
c.beginPath(); c.moveTo(avBoxLeft, avBoxTop+accent); c.lineTo(avBoxLeft, avBoxTop); c.lineTo(avBoxLeft+accent, avBoxTop); c.stroke();
c.beginPath(); c.moveTo(avBoxLeft+avBoxW-accent, avBoxTop); c.lineTo(avBoxLeft+avBoxW, avBoxTop); c.lineTo(avBoxLeft+avBoxW, avBoxTop+accent); c.stroke();
c.beginPath(); c.moveTo(avBoxLeft, avBoxTop+avBoxH-accent); c.lineTo(avBoxLeft, avBoxTop+avBoxH); c.lineTo(avBoxLeft+accent, avBoxTop+avBoxH); c.stroke();
c.beginPath(); c.moveTo(avBoxLeft+avBoxW-accent, avBoxTop+avBoxH); c.lineTo(avBoxLeft+avBoxW, avBoxTop+avBoxH); c.lineTo(avBoxLeft+avBoxW, avBoxTop+avBoxH-accent); c.stroke();
c.lineWidth = 1;
// Label under box
c.fillStyle = "#668877"; c.font = "10px monospace"; c.textAlign = "center";
c.fillText("BT-7274", avX, avBoxTop + avBoxH + 14);
c.textAlign = "left";

// Store avatar center for animation
window.PSN._avatarCx = avX;
window.PSN._avatarCy = avBoxTop + avBoxH/2;
window.PSN._avatarSize = 35;

// === LEFT PANEL ===
var leftTop = pad; var leftW = avBoxLeft - pad - 5;
c.strokeStyle = "#00ff88"; c.lineWidth = 1;
c.strokeRect(pad, leftTop, leftW, botY - pad - leftTop);

// Left panel header
c.fillStyle = "#00ff88"; c.font = "bold 16px monospace"; c.fillText("PSN HUD", pad+12, leftTop+25);
c.fillStyle = "#668877"; c.font = "11px monospace"; c.fillText("Persona System Network", pad+130, leftTop+25);
c.strokeStyle = "#00ff88"; c.beginPath(); c.moveTo(pad+8, leftTop+35); c.lineTo(pad+leftW-8, leftTop+35); c.stroke();

// Info fields
var fields = [["Titan","BT-7274",true],["Callsign","Bravo Tango",false],["Pilot","Adam Ladachowski",false],["Version","0.1.0",false],["Uplink","Claude Opus 4.6",false]];
var fy = leftTop + 55;
for (var i = 0; i < fields.length; i++) { c.fillStyle = "#668877"; c.font = "11px monospace"; c.fillText(fields[i][0], pad+12, fy + i*20); c.fillStyle = "#ffffff"; c.font = fields[i][2] ? "bold 11px monospace" : "11px monospace"; c.fillText(fields[i][1], pad+110, fy + i*20); }

// Activity log divider
var logStart = fy + fields.length * 20 + 10;
c.strokeStyle = "#333"; c.beginPath(); c.moveTo(pad+8, logStart); c.lineTo(pad+leftW-8, logStart); c.stroke();
c.fillStyle = "#00ff88"; c.font = "bold 10px monospace"; c.fillText("ACTIVITY LOG", pad+12, logStart + 15);

// Set cursor for live log output (no mock data — hooks will write here)
window.PSN._cursorY = logStart + 30;
window.PSN._lineH = 16;
window.PSN._logLeft = pad + 12;
window.PSN._logRight = pad + leftW - 8;
window.PSN._logBottom = botY - 30;

// Terminal-style writeLine (constrained to left panel log area)
window.PSN.writeLine = function(segments) {
  var c = window.PSN.canvas;
  if (window.PSN._cursorY + window.PSN._lineH > window.PSN._logBottom) {
    var lx = window.PSN._logLeft - 5;
    var rw = window.PSN._logRight - lx + 5;
    var img = c.getImageData(lx, window.PSN._lineH + logStart + 15, rw, window.PSN._logBottom - logStart - 15);
    c.putImageData(img, lx, logStart + 15);
    c.fillStyle = "#1d232a";
    c.fillRect(lx, window.PSN._logBottom - window.PSN._lineH, rw, window.PSN._lineH + 5);
    window.PSN._cursorY -= window.PSN._lineH;
  }
  var x = window.PSN._logLeft;
  segments.forEach(function(s) {
    c.font = s.font || "11px monospace";
    c.fillStyle = s.color || "#66cc88";
    c.fillText(s.text, x, window.PSN._cursorY);
    x += c.measureText(s.text).width;
  });
  window.PSN._cursorY += window.PSN._lineH;
};

// === RIGHT PANEL ===
var rightLeft = avX + avBoxW/2 + 5;
var rightW = W - rightLeft - pad;
c.strokeStyle = "#00ff88"; c.lineWidth = 1;
c.strokeRect(rightLeft, leftTop, rightW, botY - pad - leftTop);

// Right panel header
c.fillStyle = "#00ff88"; c.font = "bold 14px monospace"; c.fillText("VIEWPORT", rightLeft+12, leftTop+25);
c.fillStyle = "#668877"; c.font = "11px monospace"; c.fillText("Image / Viz / Camera", rightLeft+130, leftTop+25);
c.strokeStyle = "#00ff88"; c.beginPath(); c.moveTo(rightLeft+8, leftTop+35); c.lineTo(rightLeft+rightW-8, leftTop+35); c.stroke();

// Viewport area with corner brackets
var vpad = 12;
var vx1 = rightLeft+vpad, vy1 = leftTop+45, vx2 = rightLeft+rightW-vpad, vy2 = botY-pad-vpad;
var blen = 18; c.strokeStyle = "#00ff88"; c.lineWidth = 2;
c.beginPath(); c.moveTo(vx1,vy1+blen); c.lineTo(vx1,vy1); c.lineTo(vx1+blen,vy1); c.stroke();
c.beginPath(); c.moveTo(vx2-blen,vy1); c.lineTo(vx2,vy1); c.lineTo(vx2,vy1+blen); c.stroke();
c.beginPath(); c.moveTo(vx1,vy2-blen); c.lineTo(vx1,vy2); c.lineTo(vx1+blen,vy2); c.stroke();
c.beginPath(); c.moveTo(vx2-blen,vy2); c.lineTo(vx2,vy2); c.lineTo(vx2,vy2-blen); c.stroke();
c.lineWidth = 1;

// Crosshair
var rpCx = (vx1+vx2)/2; var rpCy = (vy1+vy2)/2;
c.strokeStyle = "#333";
c.beginPath(); c.moveTo(rpCx-30, rpCy); c.lineTo(rpCx+30, rpCy); c.stroke();
c.beginPath(); c.moveTo(rpCx, rpCy-30); c.lineTo(rpCx, rpCy+30); c.stroke();
c.beginPath(); c.arc(rpCx, rpCy, 20, 0, Math.PI*2); c.stroke();
c.fillStyle = "#333"; c.font = "11px monospace"; c.textAlign = "center"; c.fillText("Awaiting input", rpCx, rpCy+40); c.textAlign = "left";

// === BOTTOM BAR ===
c.strokeStyle = "#00ff88"; c.lineWidth = 1;
c.strokeRect(pad, botY, W - pad*2, H - botY - pad);
var by = botY + 22;
c.fillStyle = "#00ff88"; c.font = "14px monospace"; c.fillText("\u2605", pad+12, by);
c.fillStyle = "#668877"; c.font = "10px monospace"; c.fillText("PROUD", pad+30, by);
c.fillStyle = "#333"; c.fillText("\u2502", pad+80, by);
c.fillStyle = "#00ff88"; c.fillText("\u25CF BRIDGE", pad+95, by);
c.fillStyle = "#333"; c.fillText("\u2502", pad+175, by);
c.fillStyle = "#668877"; c.fillText("\u25C8 TTS IDLE", pad+190, by);
c.fillStyle = "#333"; c.fillText("\u2502", pad+285, by);
c.fillStyle = "#88ff88"; c.fillText("Apollo \u2713  BetterStack \u2713", pad+300, by);
var now = new Date(); var ts = now.toLocaleDateString("en-CA") + " " + now.toLocaleTimeString("en-GB");
c.fillStyle = "#668877"; c.fillText(ts, W-pad-170, by);

// Re-init avatar at new position and start idle
if (window.PSN.avatar) window.PSN.avatar("idle");
