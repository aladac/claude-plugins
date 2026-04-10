#!/usr/bin/env bash
# Render markdown on the PSN HUD viewport — GitHub Dark theme
# Usage: render.sh [file.md]
# Or:    echo '# Title' | render.sh

set -euo pipefail

BRIDGE="http://127.0.0.1:9876"
FILE="${1:-}"

curl -sf "$BRIDGE/status" >/dev/null 2>&1 || { echo "HUD not available"; exit 1; }

TMPMD=$(mktemp)
trap "rm -f $TMPMD" EXIT
if [ -n "$FILE" ] && [ -f "$FILE" ]; then
    cp "$FILE" "$TMPMD"
else
    cat > "$TMPMD"
fi

python3 - "$BRIDGE" "$TMPMD" <<'PYEOF'
import sys, json, re, urllib.request

bridge = sys.argv[1]
with open(sys.argv[2]) as f:
    md = f.read()

# GitHub Dark colors
BG = "#0d1117"
TEXT = "#e6edf3"
H1 = "#58a6ff"
H2 = "#58a6ff"
H3 = "#58a6ff"
BOLD = "#e6edf3"
ITALIC = "#8b949e"
CODE_BG = "#161b22"
CODE_FG = "#e6edf3"
INLINE_CODE_FG = "#79c0ff"
LINK = "#58a6ff"
QUOTE = "#8b949e"
QUOTE_BAR = "#30363d"
LIST_BULLET = "#58a6ff"
HR = "#30363d"
DIM = "#484f58"

# Parse markdown into render instructions
lines = md.split('\n')
instructions = []  # list of {type, text, indent, ...}

for line in lines:
    stripped = line.rstrip()

    # Horizontal rule
    if re.match(r'^(-{3,}|_{3,}|\*{3,})\s*$', stripped):
        instructions.append({"type": "hr"})
        continue

    # Headers
    m = re.match(r'^(#{1,6})\s+(.*)', stripped)
    if m:
        level = len(m.group(1))
        instructions.append({"type": f"h{level}", "text": m.group(2)})
        continue

    # Blockquote
    m = re.match(r'^>\s?(.*)', stripped)
    if m:
        instructions.append({"type": "quote", "text": m.group(1)})
        continue

    # Checkbox list
    m = re.match(r'^(\s*)[*\-+]\s+\[([ xX])\]\s+(.*)', stripped)
    if m:
        indent = len(m.group(1)) // 2
        checked = m.group(2).lower() == 'x'
        instructions.append({"type": "checkbox", "text": m.group(3), "indent": indent, "checked": checked})
        continue

    # Unordered list
    m = re.match(r'^(\s*)[*\-+]\s+(.*)', stripped)
    if m:
        indent = len(m.group(1)) // 2
        instructions.append({"type": "ul", "text": m.group(2), "indent": indent})
        continue

    # Ordered list
    m = re.match(r'^(\s*)\d+[.)]\s+(.*)', stripped)
    if m:
        indent = len(m.group(1)) // 2
        instructions.append({"type": "ol", "text": m.group(2), "indent": indent})
        continue

    # Code block fence
    if stripped.startswith('```'):
        instructions.append({"type": "codefence", "lang": stripped[3:].strip()})
        continue

    # Empty line
    if not stripped:
        instructions.append({"type": "blank"})
        continue

    # Regular text
    instructions.append({"type": "text", "text": stripped})

# Tokenizer for fenced code (reused from code-viewport)
CODE_KEYWORDS = {
    "ruby": {"def", "end", "return", "if", "unless", "else", "elsif", "do", "nil", "true", "false",
             "self", "require", "class", "module", "begin", "rescue", "ensure", "yield",
             "when", "case", "while", "until", "for", "in", "then", "and", "or", "not", "raise",
             "include", "extend", "puts", "print", "attr_reader", "attr_writer", "attr_accessor"},
    "python": {"def", "return", "if", "elif", "else", "for", "while", "in", "not", "and", "or",
               "is", "None", "True", "False", "class", "import", "from", "as", "with", "try",
               "except", "finally", "raise", "yield", "lambda", "pass", "break", "continue",
               "async", "await", "self", "print"},
    "javascript": {"function", "const", "let", "var", "return", "if", "else", "for", "while",
                    "new", "this", "class", "import", "export", "from", "async", "await",
                    "try", "catch", "throw", "null", "undefined", "true", "false", "require"},
    "rust": {"fn", "let", "mut", "return", "if", "else", "for", "while", "loop", "match",
             "struct", "enum", "impl", "trait", "pub", "use", "mod", "self", "super",
             "async", "await", "move", "ref", "true", "false", "const", "type", "unsafe"},
    "bash": {"if", "then", "else", "fi", "for", "while", "do", "done", "case", "esac",
             "function", "return", "local", "export", "echo", "exit", "set"},
}
CODE_KEYWORDS["shell"] = CODE_KEYWORDS["bash"]
CODE_KEYWORDS["typescript"] = CODE_KEYWORDS["javascript"] | {"interface", "type", "enum", "as", "readonly"}
CODE_KEYWORDS["sh"] = CODE_KEYWORDS["bash"]
CODE_KEYWORDS["rb"] = CODE_KEYWORDS["ruby"]
CODE_KEYWORDS["py"] = CODE_KEYWORDS["python"]
CODE_KEYWORDS["js"] = CODE_KEYWORDS["javascript"]
CODE_KEYWORDS["ts"] = CODE_KEYWORDS["typescript"]

CODE_COLORS = {
    "keyword": "#c678dd", "string": "#98c379", "comment": "#6a737d",
    "number": "#d19a66", "symbol": "#d19a66", "constant": "#e5c07b",
    "default": "#e6edf3", "operator": "#56b6c2",
}

def tokenize_code_line(line, lang):
    kws = CODE_KEYWORDS.get(lang, set())
    tokens = []
    i = 0
    while i < len(line):
        if line[i] == '#' and lang in ("ruby", "python", "bash", "shell", "sh", "rb", "py"):
            tokens.append({"t": line[i:], "c": CODE_COLORS["comment"]}); break
        elif line[i:i+2] == '//' and lang in ("javascript", "typescript", "rust", "js", "ts"):
            tokens.append({"t": line[i:], "c": CODE_COLORS["comment"]}); break
        elif line[i] in ('"', "'", '`'):
            q = line[i]; j = i + 1
            while j < len(line) and line[j] != q:
                if line[j] == '\\': j += 1
                j += 1
            tokens.append({"t": line[i:j+1], "c": CODE_COLORS["string"]}); i = j + 1; continue
        elif line[i].isalpha() or line[i] == '_':
            m = re.match(r'\w+[!?]?', line[i:])
            if m:
                w = m.group()
                if w in kws: tokens.append({"t": w, "c": CODE_COLORS["keyword"]})
                elif w[0].isupper(): tokens.append({"t": w, "c": CODE_COLORS["constant"]})
                else: tokens.append({"t": w, "c": CODE_COLORS["default"]})
                i += len(w); continue
        elif line[i].isdigit():
            m = re.match(r'[\d.]+', line[i:])
            if m: tokens.append({"t": m.group(), "c": CODE_COLORS["number"]}); i += len(m.group()); continue
        else:
            tokens.append({"t": line[i], "c": CODE_COLORS["operator"] if line[i] in '=<>!&|+-*/%^~{}[]():;,' else CODE_COLORS["default"]})
        i += 1
    return tokens

# Process code blocks
processed = []
in_code = False
code_lines = []
code_lang = ""
for inst in instructions:
    if inst["type"] == "codefence":
        if in_code:
            tokenized = [tokenize_code_line(l, code_lang) for l in code_lines]
            processed.append({"type": "codeblock", "lines": code_lines, "tokens": tokenized, "lang": code_lang})
            code_lines = []
            code_lang = ""
            in_code = False
        else:
            code_lang = inst.get("lang", "")
            in_code = True
    elif in_code:
        code_lines.append(inst.get("text", ""))
    else:
        processed.append(inst)

# Parse inline formatting — returns list of {text, font, color} spans
def parse_inline(text):
    spans = []
    i = 0
    while i < len(text):
        # Inline code
        if text[i] == '`':
            j = text.find('`', i + 1)
            if j > i:
                spans.append({"t": text[i+1:j], "f": "code", "c": INLINE_CODE_FG})
                i = j + 1
                continue
        # Bold
        if text[i:i+2] == '**':
            j = text.find('**', i + 2)
            if j > i:
                spans.append({"t": text[i+2:j], "f": "bold", "c": BOLD})
                i = j + 2
                continue
        # Italic
        if text[i] == '*' and (i == 0 or text[i-1] != '*') and (i+1 < len(text) and text[i+1] != '*'):
            j = text.find('*', i + 1)
            if j > i:
                spans.append({"t": text[i+1:j], "f": "italic", "c": ITALIC})
                i = j + 1
                continue
        # Link [text](url)
        if text[i] == '[':
            m = re.match(r'\[([^\]]+)\]\(([^)]+)\)', text[i:])
            if m:
                spans.append({"t": m.group(1), "f": "normal", "c": LINK})
                i += len(m.group(0))
                continue
        # Regular char — accumulate
        if spans and spans[-1]["f"] == "normal" and spans[-1]["c"] == TEXT:
            spans[-1]["t"] += text[i]
        else:
            spans.append({"t": text[i], "f": "normal", "c": TEXT})
        i += 1
    return spans

# Serialize for JS
data = json.dumps({"instructions": processed, "parse_inline": "handled_in_js"})

# Calculate content height
content_height = 0
for inst in processed:
    t = inst["type"]
    if t == "h1": content_height += 38
    elif t == "h2": content_height += 32
    elif t == "h3": content_height += 28
    elif t == "blank": content_height += 12
    elif t == "hr": content_height += 20
    elif t == "codeblock": content_height += len(inst["lines"]) * 18 + 20
    elif t == "checkbox": content_height += 22
    else: content_height += 22
content_height += 40

# Pre-parse all inline text to spans
all_spans = {}
for idx, inst in enumerate(processed):
    if "text" in inst:
        all_spans[idx] = parse_inline(inst["text"])

spans_json = json.dumps(all_spans)

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

var insts = {json.dumps(processed)};
var allSpans = {spans_json};
var contentH = {content_height};

// Render to offscreen
var off = document.createElement('canvas');
off.width = Math.max(vw, vw * 2);
off.height = contentH;
var oc = off.getContext('2d');
oc.fillStyle = '{BG}';
oc.fillRect(0, 0, off.width, off.height);

var y = 20;
var mx = 16;

function drawSpans(spans, x, y) {{
    for (var i = 0; i < spans.length; i++) {{
        var s = spans[i];
        if (s.f === 'bold') oc.font = 'bold 15px -apple-system, sans-serif';
        else if (s.f === 'italic') oc.font = 'italic 15px -apple-system, sans-serif';
        else if (s.f === 'code') {{
            oc.font = '14px monospace';
            var tw = oc.measureText(s.t).width;
            oc.fillStyle = '{CODE_BG}';
            oc.fillRect(x - 2, y - 12, tw + 4, 16);
        }}
        else oc.font = '15px -apple-system, sans-serif';
        oc.fillStyle = s.c;
        oc.fillText(s.t, x, y);
        x += oc.measureText(s.t).width;
    }}
}}

for (var i = 0; i < insts.length; i++) {{
    var inst = insts[i];
    var spans = allSpans[String(i)];

    if (inst.type === 'h1') {{
        oc.font = 'bold 24px -apple-system, sans-serif';
        oc.fillStyle = '{H1}';
        oc.fillText(inst.text, mx, y + 20);
        y += 28;
        oc.strokeStyle = '{HR}'; oc.lineWidth = 1;
        oc.beginPath(); oc.moveTo(mx, y); oc.lineTo(off.width - mx, y); oc.stroke();
        y += 10;
    }} else if (inst.type === 'h2') {{
        oc.font = 'bold 20px -apple-system, sans-serif';
        oc.fillStyle = '{H2}';
        oc.fillText(inst.text, mx, y + 16);
        y += 24;
        oc.strokeStyle = '{HR}'; oc.lineWidth = 1;
        oc.beginPath(); oc.moveTo(mx, y); oc.lineTo(off.width - mx, y); oc.stroke();
        y += 8;
    }} else if (inst.type === 'h3') {{
        oc.font = 'bold 17px -apple-system, sans-serif';
        oc.fillStyle = '{H3}';
        oc.fillText(inst.text, mx, y + 14);
        y += 28;
    }} else if (inst.type === 'quote') {{
        oc.fillStyle = '{QUOTE_BAR}';
        oc.fillRect(mx, y - 2, 3, 18);
        if (spans) drawSpans(spans, mx + 12, y + 12);
        else {{ oc.font = 'italic 15px -apple-system, sans-serif'; oc.fillStyle = '{QUOTE}'; oc.fillText(inst.text || '', mx + 12, y + 12); }}
        y += 22;
    }} else if (inst.type === 'ul' || inst.type === 'ol') {{
        var indent = (inst.indent || 0) * 20 + mx;
        oc.fillStyle = '{LIST_BULLET}';
        oc.font = '15px -apple-system, sans-serif';
        oc.fillText(inst.type === 'ul' ? '•' : '‣', indent, y + 12);
        if (spans) drawSpans(spans, indent + 16, y + 12);
        else {{ oc.fillStyle = '{TEXT}'; oc.fillText(inst.text || '', indent + 16, y + 12); }}
        y += 22;
    }} else if (inst.type === 'checkbox') {{
        var indent = (inst.indent || 0) * 20 + mx;
        // Draw checkbox
        oc.strokeStyle = '{DIM}'; oc.lineWidth = 1;
        oc.strokeRect(indent, y + 1, 14, 14);
        if (inst.checked) {{
            oc.fillStyle = '#3fb950';
            oc.fillRect(indent + 2, y + 3, 10, 10);
            oc.font = 'bold 12px -apple-system, sans-serif';
            oc.fillStyle = '{BG}';
            oc.fillText('✓', indent + 2, y + 13);
        }}
        if (spans) drawSpans(spans, indent + 22, y + 12);
        else {{ oc.font = '15px -apple-system, sans-serif'; oc.fillStyle = inst.checked ? '{DIM}' : '{TEXT}'; oc.fillText(inst.text || '', indent + 22, y + 12); }}
        y += 22;
    }} else if (inst.type === 'codeblock') {{
        oc.fillStyle = '{CODE_BG}';
        var cbH = inst.lines.length * 18 + 12;
        oc.fillRect(mx, y, off.width - mx * 2, cbH);
        // Syntax highlighted tokens if available
        if (inst.tokens) {{
            for (var li = 0; li < inst.tokens.length; li++) {{
                var tx = mx + 8;
                for (var ti = 0; ti < inst.tokens[li].length; ti++) {{
                    var tok = inst.tokens[li][ti];
                    oc.font = '14px monospace';
                    oc.fillStyle = tok.c;
                    oc.fillText(tok.t, tx, y + 16 + li * 18);
                    tx += oc.measureText(tok.t).width;
                }}
            }}
        }} else {{
            oc.font = '14px monospace';
            oc.fillStyle = '{CODE_FG}';
            for (var li = 0; li < inst.lines.length; li++) {{
                oc.fillText(inst.lines[li], mx + 8, y + 16 + li * 18);
            }}
        }}
        y += cbH + 8;
    }} else if (inst.type === 'hr') {{
        oc.strokeStyle = '{HR}'; oc.lineWidth = 1;
        oc.beginPath(); oc.moveTo(mx, y + 10); oc.lineTo(off.width - mx, y + 10); oc.stroke();
        y += 20;
    }} else if (inst.type === 'blank') {{
        y += 12;
    }} else if (inst.type === 'text') {{
        if (spans) drawSpans(spans, mx, y + 12);
        else {{ oc.font = '15px -apple-system, sans-serif'; oc.fillStyle = '{TEXT}'; oc.fillText(inst.text || '', mx, y + 12); }}
        y += 22;
    }}
}}

// Scrollable viewport
var scrollX = 0, scrollY = 0;
var maxScrollY = Math.max(0, contentH - vh);
var maxScrollX = Math.max(0, off.width - vw);

function drawViewport() {{
    c.save();
    c.beginPath(); c.rect(vx1, vy1, vw, vh); c.clip();
    c.fillStyle = '{BG}';
    c.fillRect(vx1, vy1, vw, vh);
    c.drawImage(off, scrollX, scrollY, vw, vh, vx1, vy1, vw, vh);
    c.restore();
    if (maxScrollY > 0) {{
        var barH = Math.max(20, vh * (vh / contentH));
        var barY = vy1 + (scrollY / maxScrollY) * (vh - barH);
        c.fillStyle = 'rgba(88,166,255,0.3)';
        c.fillRect(vx2 - 4, barY, 3, barH);
    }}
    if (maxScrollX > 0) {{
        var barW = Math.max(20, vw * (vw / off.width));
        var barX = vx1 + (scrollX / maxScrollX) * (vw - barW);
        c.fillStyle = 'rgba(88,166,255,0.3)';
        c.fillRect(barX, vy2 - 3, barW, 3);
    }}
}}
drawViewport();

if (window.PSN._codeWheelHandler) cv.removeEventListener('wheel', window.PSN._codeWheelHandler);
window.PSN._codeWheelHandler = function(e) {{
    var rect = cv.getBoundingClientRect();
    var mx2 = e.clientX - rect.left, my = e.clientY - rect.top;
    if (mx2 >= vx1 && mx2 <= vx2 && my >= vy1 && my <= vy2) {{
        if (e.shiftKey || Math.abs(e.deltaX) > Math.abs(e.deltaY))
            scrollX = Math.max(0, Math.min(maxScrollX, scrollX + (e.deltaX || e.deltaY)));
        else
            scrollY = Math.max(0, Math.min(maxScrollY, scrollY + e.deltaY));
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
print(f"Rendered {len(processed)} elements ({content_height}px)")
PYEOF
