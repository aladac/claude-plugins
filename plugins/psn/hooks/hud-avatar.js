window.PSN._avatarAnim = null;
window.PSN._avatarState = "idle";
window.PSN._avatarCx = window.PSN._avatarCx || 60;
window.PSN._avatarCy = window.PSN._avatarCy || 60;
window.PSN._avatarSize = window.PSN._avatarSize || 35;

window.PSN.avatar = function(state) {
  if (window.PSN._avatarAnim) { cancelAnimationFrame(window.PSN._avatarAnim); window.PSN._avatarAnim = null; }
  window.PSN._avatarState = state || "idle";
  var c = window.PSN.canvas;
  var cx = window.PSN._avatarCx;
  var cy = window.PSN._avatarCy;
  var size = window.PSN._avatarSize;
  var frame = 0;

  function draw() {
    c.save();
    // Clear only inside the avatar box (80x80 at avBoxLeft, avBoxTop)
    var bw = 78, bh = 78;
    c.fillStyle = "#1d232a";
    c.fillRect(cx-bw/2, cy-bh/2, bw, bh);
    var s = window.PSN._avatarState;
    var t = frame * 0.05;
    c.strokeStyle = "#00ff88"; c.lineWidth = 2;
    c.beginPath(); c.arc(cx, cy, size, 0, Math.PI * 2); c.stroke();
    if (s === "idle") {
      c.fillStyle = "#00ff88"; c.beginPath(); c.arc(cx, cy, 8, 0, Math.PI * 2); c.fill();
      c.strokeStyle = "#00ff8844"; c.lineWidth = 1; c.beginPath(); c.arc(cx, cy, 18, 0, Math.PI * 2); c.stroke();
      c.restore(); return;
    }
    if (s === "speaking") {
      var pulse = Math.sin(t * 3) * 0.5 + 0.5; var r = 6 + pulse * 6;
      c.fillStyle = "#00ff88"; c.beginPath(); c.arc(cx, cy, r, 0, Math.PI * 2); c.fill();
      for (var i = 0; i < 3; i++) { var rr = 15 + ((frame * 0.8 + i * 12) % 25); var alpha = 1 - (rr - 15) / 25; c.strokeStyle = "rgba(0,255,136," + (alpha * 0.6) + ")"; c.lineWidth = 1; c.beginPath(); c.arc(cx, cy, rr, 0, Math.PI * 2); c.stroke(); }
    }
    if (s === "thinking") {
      c.fillStyle = "#00ff88"; c.beginPath(); c.arc(cx, cy, 6, 0, Math.PI * 2); c.fill();
      for (var i = 0; i < 4; i++) { var angle = t * 2 + (i * Math.PI / 2); c.strokeStyle = "#00ff88"; c.lineWidth = 2; c.beginPath(); c.arc(cx, cy, 22, angle, angle + 0.5); c.stroke(); }
    }
    if (s === "working") {
      c.fillStyle = "#00ff88"; c.beginPath(); c.arc(cx, cy, 7, 0, Math.PI * 2); c.fill();
      var sweep = (t * 1.5) % (Math.PI * 2); c.strokeStyle = "#00ff88"; c.lineWidth = 3; c.beginPath(); c.arc(cx, cy, 25, sweep, sweep + Math.PI * 1.2); c.stroke();
      c.strokeStyle = "#00ff8844"; c.lineWidth = 1; c.beginPath(); c.arc(cx, cy, 25, 0, Math.PI * 2); c.stroke();
    }
    c.restore(); frame++;
    window.PSN._avatarAnim = requestAnimationFrame(draw);
  }
  draw();
};
window.PSN.avatar("idle");
