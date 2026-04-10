---
name: LaTeX CV & Documents
description: |
  Build LaTeX CVs, cover letters, and generate skill pill images. Manages Adam's CV at ~/Projects/cv/ with pdflatex, ImageMagick pill generation, and fswatch auto-rebuild.

  <example>
  Context: User wants to build the CV
  user: "build my cv"
  </example>

  <example>
  Context: User wants to create a new skill pill
  user: "generate a pill for Terraform"
  </example>

  <example>
  Context: User wants to see the CV
  user: "open my cv"
  </example>

  <example>
  Context: User wants to build a cover letter
  user: "build the cover letter"
  </example>
version: 1.0.0
---

# LaTeX CV & Documents Skill

Build and manage Adam's LaTeX CV, cover letters, and skill pill images.

## Quick Reference

```bash
SKILL=~/Projects/personality-plugin/skills/latex/latex.sh

# Build CV
bash $SKILL build-cv

# Build cover letter
bash $SKILL build-cover

# Build any .tex file
bash $SKILL build somefile.tex

# Open CV in Preview
bash $SKILL open

# Generate a skill pill
bash $SKILL pill source-icon.png "Terraform"

# List all pill images
bash $SKILL pill-list

# Check dependencies
bash $SKILL check

# Clean build artifacts
bash $SKILL clean

# Watch and auto-rebuild
bash $SKILL watch
```

## Environment

| Tool | Path | Version |
|------|------|---------|
| pdflatex | `/Library/TeX/texbin/pdflatex` | TeX Live 2026 |
| ImageMagick | `magick` (Homebrew) | For pill generation |
| Ruby | system | For generate_label.rb |
| fswatch | Homebrew | For just watch |
| just | Homebrew | Task runner |

**IMPORTANT:** pdflatex is NOT on the default PATH. Always use the full path `/Library/TeX/texbin/pdflatex` or this skill's commands.

## CV Project Layout

```
~/Projects/cv/
  cv.tex                  # Main CV (2 pages, skill pills)
  cv-dist.tex             # Distribution variant (no projects section)
  cover.tex               # Cover letter template
  cv.pdf / cv-dist.pdf    # Built PDFs
  img/                    # 125 skill pill PNGs (2200x482px, grayscale)
  generate_label/         # Ruby script for pill generation
    generate_label.rb     # Main generator (ImageMagick)
  doc/                    # Company research docs
    comverga.md
    cyfrowy-polsat.md
    jampack.md
    marketer-tech.md
    roomzilla.md
  justfile                # Build tasks (build, watch, clean)
  DISTRIBUSION.md         # Interview prep notes
  JAMPACK.md              # Jampack role notes
  JOB.md                  # Job search notes
  NOTES.md                # General CV notes
  QUESTIONS.md            # Interview questions
```

## CV Architecture

**cv.tex** — single-file LaTeX document:

- **Lines 7-25:** PDF metadata (pdfkeywords stuffed for SEO/ATS)
- **Lines 33-44:** URL macros (\jampackUrl, \roomzillaUrl, etc.)
- **Lines 45:** `\imgPath` — absolute path to img/ (update if project moves)
- **Lines 54-110:** Pill row macros (\sixrow, \fiverow, \fourrow, etc.)
- **Lines 114-134:** Job entry and achievement macros
- **Lines 136-158:** Header, summary, contact info
- **Lines 165-210:** ACHIEVEMENTS section (4 entries)
- **Lines 213-242:** PROFESSIONAL EXPERIENCE (5 roles)
- **Lines 244-297:** SKILLS section (pill images by category)
- **After pills:** ATS-invisible text block (white 1pt text with all keywords)

### ATS Keyword Strategy

Skills are displayed as **PNG pill images** (visual wow factor for humans) but are invisible to ATS parsers. Two countermeasures:

1. **pdfkeywords metadata** — stuffed with ~100 keywords (lines 11-24)
2. **Invisible text block** — 1pt white text after skills section with all keywords as parseable text

### Pill Image Categories

| Category | Count | Examples |
|----------|-------|---------|
| Code — Primary | 9 | ruby, rails, grape, javascript, typescript, stimulus, turbo, nuxt, python |
| Code — Exposure | 6 | fastapi, vuejs, nextjs, react, rust, crystal |
| AI — Tools | 6 | warp, zed, claude, copilot, lmstudio, comfyui |
| AI — Code | 8 | mcp, acp, ollama, openai, llm, vlm, diffusion, rag |
| Layout | 6 | html5, css3, bootstrap, fontawesome, openprops, tailwindcss |
| Data & Storage | 5 | postgresql, redis, mongodb, mysql, elastic |
| Async & Queues | 3 | sidekiq, resque, rabbitmq |
| CI & Testing | 6 | rspec, gh-actions, playwright, cypress, jest, pytest |
| Deployment & Cloud | 5 | docker, kubernetes, aws, gcp, heroku |
| API & SDK | 6 | openapi, stripe, coinbase, google, ms-graph, twilio |

### Generating New Pills

All pills are **2200x482px, grayscale/monochrome**. Generator uses ImageMagick + Ruby:

```bash
# From the cv directory:
ruby generate_label/generate_label.rb \
  -i generate_label/source-icon.png \
  -t "LABEL" -w 2200 -o img/name.png --grayscale
```

Always use `--grayscale`. Source icons should be high-contrast PNGs.

## Cover Letter

`cover.tex` is a generic template. Customize the body for each application. Same LaTeX font and styling as the CV for consistency.

## Build Notes

- `just watch` should be running in a background terminal — auto-rebuilds on save
- If not running, use `bash latex.sh build-cv` or `bash latex.sh build`
- The justfile `rm -f *.png` after build cleans pdflatex artifacts (not the img/ pills)
- `\imgPath` is absolute (`/Users/chi/Projects/docs/cv/img`) — NOTE: this path may be stale if project was moved. Current location is `~/Projects/cv/img`

## Prerequisites

- TeX Live 2026 at `/Library/TeX/texbin/`
- ImageMagick (`brew install imagemagick`)
- Ruby (system or brew)
- fswatch (`brew install fswatch`)
- just (`brew install just`)
