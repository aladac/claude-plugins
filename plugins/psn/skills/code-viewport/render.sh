#!/usr/bin/env bash
# Render syntax-highlighted code on the PSN HUD viewport
# Usage: render.sh <language> [file]
# Or:    echo 'code' | render.sh <language>

set -euo pipefail

BRIDGE="http://127.0.0.1:9876"
LANG="${1:-ruby}"
FILE="${2:-}"

# Bail if HUD is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || { echo "HUD not available"; exit 1; }

# Read code from file or stdin into a temp file (preserves newlines)
TMPCODE=$(mktemp)
trap "rm -f $TMPCODE" EXIT
if [ -n "$FILE" ] && [ -f "$FILE" ]; then
    cp "$FILE" "$TMPCODE"
else
    cat > "$TMPCODE"
fi

# Tokenize and render via Python
python3 - "$LANG" "$BRIDGE" "$TMPCODE" <<'PYEOF'
import sys, json, re, urllib.request

lang = sys.argv[1]
bridge = sys.argv[2]
with open(sys.argv[3]) as f:
    code = f.read()

# One Dark color scheme
COLORS = {
    "keyword": "#c678dd",
    "string": "#98c379",
    "comment": "#6a737d",
    "number": "#d19a66",
    "symbol": "#d19a66",
    "constant": "#e5c07b",
    "builtin": "#61afef",
    "operator": "#56b6c2",
    "default": "#abb2bf",
}

# Language keyword sets
KEYWORDS = {
    "ruby": {"def", "end", "return", "if", "unless", "else", "elsif", "do", "nil", "true", "false",
             "self", "require", "class", "module", "begin", "rescue", "ensure", "yield", "block",
             "when", "case", "while", "until", "for", "in", "then", "and", "or", "not", "raise",
             "attr_reader", "attr_writer", "attr_accessor", "include", "extend", "puts", "print"},
    "python": {"def", "return", "if", "elif", "else", "for", "while", "in", "not", "and", "or",
               "is", "None", "True", "False", "class", "import", "from", "as", "with", "try",
               "except", "finally", "raise", "yield", "lambda", "pass", "break", "continue",
               "async", "await", "self", "print"},
    "javascript": {"function", "const", "let", "var", "return", "if", "else", "for", "while",
                    "do", "switch", "case", "break", "continue", "new", "this", "class", "import",
                    "export", "from", "default", "async", "await", "try", "catch", "finally",
                    "throw", "typeof", "instanceof", "null", "undefined", "true", "false",
                    "console", "require"},
    "typescript": {"function", "const", "let", "var", "return", "if", "else", "for", "while",
                    "do", "switch", "case", "break", "continue", "new", "this", "class", "import",
                    "export", "from", "default", "async", "await", "try", "catch", "finally",
                    "throw", "typeof", "instanceof", "null", "undefined", "true", "false",
                    "interface", "type", "enum", "implements", "extends", "as", "readonly"},
    "rust": {"fn", "let", "mut", "return", "if", "else", "for", "while", "loop", "match",
             "struct", "enum", "impl", "trait", "pub", "use", "mod", "crate", "self", "super",
             "where", "async", "await", "move", "ref", "true", "false", "None", "Some", "Ok",
             "Err", "Self", "const", "static", "type", "unsafe", "extern"},
    "bash": {"if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case", "esac",
             "in", "function", "return", "local", "export", "source", "echo", "exit", "set",
             "unset", "readonly", "shift", "cd", "pwd", "true", "false"},
}
KEYWORDS["shell"] = KEYWORDS["bash"]

kw_set = KEYWORDS.get(lang, KEYWORDS["ruby"])

def tokenize_line(line):
    tokens = []
    i = 0
    while i < len(line):
        # Comment
        if line[i] == '#' and lang in ("ruby", "python", "bash", "shell"):
            tokens.append({"t": line[i:], "c": COLORS["comment"]})
            break
        elif line[i:i+2] == '//' and lang in ("javascript", "typescript", "rust"):
            tokens.append({"t": line[i:], "c": COLORS["comment"]})
            break
        # String
        elif line[i] in ('"', "'", '`'):
            q = line[i]
            j = i + 1
            while j < len(line) and line[j] != q:
                if line[j] == '\\': j += 1
                j += 1
            tokens.append({"t": line[i:j+1], "c": COLORS["string"]})
            i = j + 1
            continue
        # Symbol (Ruby)
        elif line[i] == ':' and i+1 < len(line) and line[i+1].isalpha() and lang == "ruby":
            m = re.match(r':\w+', line[i:])
            if m:
                tokens.append({"t": m.group(), "c": COLORS["symbol"]})
                i += len(m.group())
                continue
        # Word
        elif line[i].isalpha() or line[i] == '_':
            m = re.match(r'\w+[!?]?', line[i:])
            if m:
                word = m.group()
                if word in kw_set:
                    tokens.append({"t": word, "c": COLORS["keyword"]})
                elif word[0].isupper():
                    tokens.append({"t": word, "c": COLORS["constant"]})
                else:
                    tokens.append({"t": word, "c": COLORS["default"]})
                i += len(word)
                continue
        # Number
        elif line[i].isdigit():
            m = re.match(r'[\d.]+', line[i:])
            if m:
                tokens.append({"t": m.group(), "c": COLORS["number"]})
                i += len(m.group())
                continue
        # Everything else
        else:
            tokens.append({"t": line[i], "c": COLORS["operator"] if line[i] in '=<>!&|+-*/%^~' else COLORS["default"]})
        i += 1
    return tokens

lines = code.rstrip().split('\n')
all_tokens = [tokenize_line(l) for l in lines]

# Build JS — render to offscreen canvas, mousewheel scrollable
font_size = 15
line_height = 20
total_height = len(all_tokens) * line_height + 40

# Serialize tokens as JSON for the JS side
tokens_json = json.dumps(all_tokens)

js = f"""
(function() {{
var c = window.PSN.canvas;
var cv = c.canvas;
var W = cv.width, H = cv.height;
var pad = 20, avBoxW = 120, avX = Math.floor(W/2);
var rL = avX + avBoxW/2 + 5, rW = W - rL - pad;
var vp = 14;
var vx1 = rL + vp, vy1 = pad + 55, vx2 = rL + rW - vp, vy2 = H - 110 - pad - vp;
var vw = vx2 - vx1, vh = vy2 - vy1;

// Render all lines to offscreen canvas (wide enough for longest line)
var off = document.createElement('canvas');
off.width = Math.max(vw, vw * 3);
off.height = {total_height};
var oc = off.getContext('2d');
oc.fillStyle = '#282c34';
oc.fillRect(0, 0, off.width, off.height);

var tokens = {tokens_json};
var y = 18;
for (var i = 0; i < tokens.length; i++) {{
    var x = 10;
    for (var j = 0; j < tokens[i].length; j++) {{
        var tok = tokens[i][j];
        oc.font = '{font_size}px monospace';
        oc.fillStyle = tok.c;
        oc.fillText(tok.t, x, y);
        x += oc.measureText(tok.t).width;
    }}
    y += {line_height};
}}

// Language label
oc.font = 'bold 12px monospace';
oc.fillStyle = '#6a737d';
oc.fillText('{lang.upper()}', vw - 60, 15);

// Measure actual content width
var maxLineWidth = 0;
for (var i = 0; i < tokens.length; i++) {{
    var x = 10;
    for (var j = 0; j < tokens[i].length; j++) {{
        oc.font = '{font_size}px monospace';
        x += oc.measureText(tokens[i][j].t).width;
    }}
    if (x > maxLineWidth) maxLineWidth = x;
}}
maxLineWidth += 20;

// Resize offscreen if content is wider
if (maxLineWidth > off.width) {{
    var oldImg = oc.getImageData(0, 0, off.width, off.height);
    off.width = maxLineWidth;
    oc.putImageData(oldImg, 0, 0);
    // Re-render (canvas cleared on resize)
    oc.fillStyle = '#282c34';
    oc.fillRect(0, 0, off.width, off.height);
    var ry = 18;
    for (var i = 0; i < tokens.length; i++) {{
        var rx = 10;
        for (var j = 0; j < tokens[i].length; j++) {{
            oc.font = '{font_size}px monospace';
            oc.fillStyle = tokens[i][j].c;
            oc.fillText(tokens[i][j].t, rx, ry);
            rx += oc.measureText(tokens[i][j].t).width;
        }}
        ry += {line_height};
    }}
    oc.font = 'bold 12px monospace';
    oc.fillStyle = '#6a737d';
    oc.fillText('{lang.upper()}', off.width - 60, 15);
}}

// Draw visible portion
var scrollX = 0, scrollY = 0;
var maxScrollY = Math.max(0, {total_height} - vh);
var maxScrollX = Math.max(0, maxLineWidth - vw);

function drawViewport() {{
    c.save();
    c.beginPath();
    c.rect(vx1, vy1, vw, vh);
    c.clip();
    c.fillStyle = '#282c34';
    c.fillRect(vx1, vy1, vw, vh);
    c.drawImage(off, scrollX, scrollY, vw, vh, vx1, vy1, vw, vh);
    c.restore();
    // Vertical scroll indicator
    if (maxScrollY > 0) {{
        var barH = Math.max(20, vh * (vh / {total_height}));
        var barY = vy1 + (scrollY / maxScrollY) * (vh - barH);
        c.fillStyle = 'rgba(0,255,136,0.3)';
        c.fillRect(vx2 - 4, barY, 3, barH);
    }}
    // Horizontal scroll indicator
    if (maxScrollX > 0) {{
        var barW = Math.max(20, vw * (vw / maxLineWidth));
        var barX = vx1 + (scrollX / maxScrollX) * (vw - barW);
        c.fillStyle = 'rgba(0,255,136,0.3)';
        c.fillRect(barX, vy2 - 3, barW, 3);
    }}
}}
drawViewport();

// Mouse wheel scroll — vertical + shift for horizontal
if (window.PSN._codeWheelHandler) {{
    cv.removeEventListener('wheel', window.PSN._codeWheelHandler);
}}
window.PSN._codeWheelHandler = function(e) {{
    var rect = cv.getBoundingClientRect();
    var mx = e.clientX - rect.left;
    var my = e.clientY - rect.top;
    if (mx >= vx1 && mx <= vx2 && my >= vy1 && my <= vy2) {{
        if (e.shiftKey || Math.abs(e.deltaX) > Math.abs(e.deltaY)) {{
            scrollX = Math.max(0, Math.min(maxScrollX, scrollX + (e.deltaX || e.deltaY)));
        }} else {{
            scrollY = Math.max(0, Math.min(maxScrollY, scrollY + e.deltaY));
        }}
        drawViewport();
        e.preventDefault();
    }}
}};
cv.addEventListener('wheel', window.PSN._codeWheelHandler, {{passive: false}});
}})();
"""

payload = json.dumps({"script": js})
req = urllib.request.Request(f"{bridge}/eval", data=payload.encode(), headers={"Content-Type": "application/json"})
urllib.request.urlopen(req)
print(f"Rendered {len(lines)} lines of {lang} ({total_height}px, viewport scrollable)")
PYEOF
