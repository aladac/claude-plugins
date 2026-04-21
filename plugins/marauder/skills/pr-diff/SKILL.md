---
name: PR Diff Preview
description: |
  Generate GitHub-style HTML diff previews locally without pushing branches. Uses diff2html to render unified or side-by-side diffs in the browser. Supports single branch diffs or multi-step PR previews.

  <example>
  Context: User wants to preview a PR diff locally
  user: "preview the diff for this branch"
  </example>

  <example>
  Context: User has stacked branches to preview
  user: "preview all three PR diffs"
  </example>

  <example>
  Context: User wants side-by-side view
  user: "show me the diff side by side"
  </example>
---

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/pr-diff/pr-diff.sh [options] <base>..<head> [<base>..<head> ...]
```

### Single branch diff
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/pr-diff/pr-diff.sh development..feature-branch
```

### Multiple stacked diffs
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/pr-diff/pr-diff.sh \
  development..step1-branch \
  step1-branch..step2-branch \
  step2-branch..step3-branch
```

### Side-by-side view
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/pr-diff/pr-diff.sh --side development..feature-branch
```

### Waterfall (cumulative from root base)
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/pr-diff/pr-diff.sh --waterfall \
  development..step1-branch \
  step1-branch..step2-branch \
  step2-branch..step3-branch
```

Rewrites ranges to show cumulative diffs from the root base:
- `development..step1` — step 1 only
- `development..step2` — step 1 + 2
- `development..step3` — step 1 + 2 + 3

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--side` | off | Side-by-side view (default: unified) |
| `--waterfall` | off | Cumulative diffs from root base |
| `--no-open` | off | Generate files without opening browser |
| `--output` | `/tmp/pr-diff` | Output directory |

### Output

- Generates HTML files in the output directory
- Creates an `index.html` linking all diffs when multiple ranges given
- Opens in default browser unless `--no-open` is set

### Prerequisites

- `diff2html-cli` (`npm install -g diff2html-cli`)
- `git` with access to the branches being compared
