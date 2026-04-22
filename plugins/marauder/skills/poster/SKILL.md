---
name: poster
description: |
  Generate a cinematic landscape poster — image on the left, styled text on the right.
  Dark military aesthetic: navy background (#080c12), orange accent (#e8872b), light text (#c8d4de).
  Uses DIN Condensed Bold for titles and DIN Alternate Bold for body text.

  <example>
  Context: User wants to create a poster from an image and text
  user: "Make a poster from this mech image with the Protocol 3 speech"
  assistant: "I'll use the poster skill to generate it."
  <commentary>
  Image + text poster generation — the poster skill handles layout, fonts, and color scheme.
  </commentary>
  </example>

  <example>
  Context: User provides paragraphs separately
  user: "Create a poster with these 3 paragraphs and this background image"
  assistant: "I'll use the poster skill with separate paragraph inputs."
  <commentary>
  Multiple paragraphs get proper spacing — use --p1 through --p4 flags.
  </commentary>
  </example>
---

# Poster Generator

Generate cinematic landscape posters with the MARAUDER visual style.

## Usage

```bash
bash $SKILL --image <path> --title <title> --p1 "paragraph 1" --p2 "paragraph 2" [--p3 "..."] [--p4 "..."] [--output <path>]
bash $SKILL --image <path> --title <title> --text "single text block" [--output <path>]
echo "text from stdin" | bash $SKILL --image <path> --title <title>
```

## Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--image`, `-i` | (required) | Background image for the left panel |
| `--title`, `-t` | (required) | Title text in orange accent |
| `--p1` .. `--p4` | (optional) | Up to 4 paragraphs with proper spacing |
| `--text` | (optional) | Single text block (alternative to --p1..p4) |
| `--output`, `-o` | `~/Desktop/poster.png` | Output file path |
| `--attribution`, `-a` | `MARAUDER x BT-7274 // <date>` | Bottom attribution line |
| `--bar`, `-b` | `LINK ESTABLISHED // ...` | Orange bottom bar text |
| `--width` | `2400` | Canvas width |
| `--height` | `1350` | Canvas height |

## Layout

```
┌─────────────────────┬──────────────────────┐
│                     │  TITLE               │
│   IMAGE             │  ─────               │
│   (left half,       │  Paragraph 1         │
│    fades right)     │  Paragraph 2         │
│                     │  Paragraph 3         │
│                     │  Paragraph 4         │
│                     │  attribution         │
├─────────────────────┴──────────────────────┤
│  ████████ BOTTOM BAR TEXT █████████████████ │
└────────────────────────────────────────────┘
```

## Color Scheme

| Element | Color | Hex |
|---------|-------|-----|
| Background | Dark navy | `#080c12` |
| Accent/Title | Orange | `#e8872b` |
| Body text | Light steel | `#c8d4de` |
| Muted text | Slate | `#4a6080` |
| Divider | Orange 40% | `#e8872b66` |

## Fonts

- **Title**: DIN Condensed Bold, 72pt
- **Body**: DIN Alternate Bold, 22pt
- **Attribution**: DIN Condensed Bold, 18pt
- **Bar**: DIN Condensed Bold, 14pt

## Dependencies

- ImageMagick (`magick`)
- macOS system fonts (DIN Condensed Bold, DIN Alternate Bold)
