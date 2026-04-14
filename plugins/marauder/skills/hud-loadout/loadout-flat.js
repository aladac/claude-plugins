(function(){
  var c = window.PSN.canvas;
  var W = c.canvas.width, H = c.canvas.height;
  var G = "#00ff88", D = "#00ff8844", BG = "#1d232a";
  var pad=20, avBoxW=120, avX=Math.floor(W/2);
  var vpL=avX+avBoxW/2+5, vpW=W-vpL-pad, vpT=pad, vpH=H-110-pad;
  var cols=2, gap=14, ip=16;
  var cW=Math.floor((vpW-ip*2-gap)/cols), cH=Math.floor(cW*0.48);
  var names=["KATANA","RAILGUN","VIPER","LANCE","REACTOR","TRIDENT","FLARE","FORGE"];
  var codes=["RB-34","RS-94","PY-312","TS-58","DX-06","NET-88","CF-01","GH-10"];
  var rows=Math.ceil(names.length/cols);
  var tH=rows*cH+(rows-1)*gap+50;
  var sX=vpL+ip, sY=vpT+(vpH-tH)/2+30, cx=vpL+vpW/2;
  c.fillStyle=BG; c.fillRect(vpL,vpT,vpW,vpH);
  c.font="bold 22px monospace"; c.fillStyle=G; c.textAlign="center";
  c.fillText("LOADOUT \u2014 CODE SPECIALISTS",cx,sY-35);
  c.font="12px monospace"; c.fillStyle=D; c.fillText("WEAPONS SYSTEMS ONLINE",cx,sY-16);
  for(var i=0;i<names.length;i++){
    var row=Math.floor(i/cols), col=i%cols;
    var lr=Math.floor((names.length-1)/cols);
    var ri=(row===lr&&names.length%cols!==0)?names.length%cols:cols;
    var ox=(ri<cols)?(cW+gap)/2:0;
    var x=sX+col*(cW+gap)+ox, y=sY+row*(cH+gap);
    c.strokeStyle=G; c.lineWidth=3; c.strokeRect(x,y,cW,cH);
    var cb=12; c.lineWidth=2;
    c.beginPath();c.moveTo(x+cb,y);c.lineTo(x,y);c.lineTo(x,y+cb);c.stroke();
    c.beginPath();c.moveTo(x+cW-cb,y);c.lineTo(x+cW,y);c.lineTo(x+cW,y+cb);c.stroke();
    c.beginPath();c.moveTo(x,y+cH-cb);c.lineTo(x,y+cH);c.lineTo(x+cb,y+cH);c.stroke();
    c.beginPath();c.moveTo(x+cW,y+cH-cb);c.lineTo(x+cW,y+cH);c.lineTo(x+cW-cb,y+cH);c.stroke();
    c.font="bold 22px monospace"; c.fillStyle=G; c.textAlign="center";
    c.fillText(names[i],x+cW/2,y+cH*0.45);
    c.font="bold 14px monospace"; c.fillStyle=D;
    c.fillText(codes[i],x+cW/2,y+cH*0.7);
  }
  c.font="11px monospace"; c.fillStyle=D; c.textAlign="center";
  c.fillText("8 WEAPONS LOADED  //  PILOT AUTHORIZATION REQUIRED",cx,sY+(rows)*(cH+gap)+10);
  c.textAlign="left";
})();
