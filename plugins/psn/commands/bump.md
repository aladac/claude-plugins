---
description: Bump personality gem version, build, install, and restart MCP
---

Bump the personality gem version, build, install on both machines, and restart the MCP server.

## Instructions

Run the bump script:

```bash
~/.claude/bump.sh
```

The script automatically:
1. Reads the base version from `lib/personality/version.rb` (e.g., `0.1.5`)
2. Appends `.pre.<short-git-hash>` (e.g., `0.1.5.pre.1ac431d`)
3. Updates `version.rb`
4. Builds the gem
5. Installs on the local machine
6. SCPs and installs on the other machine (j↔f)
7. Restarts `psn-http` service on junkpile
8. Reports the installed version

After the script completes, show the user the new version and confirm all steps succeeded.

**Note:** The version.rb change is staged but NOT committed — the user decides when to commit.
