---
description: Quick session save — save current work context to memory
---
Save the current session to memory with an auto-generated or user-specified name.

## Arguments

Optional session name after `/ses`. If omitted, generate a random name.

Examples:
- `/ses` → auto-generates name like "crimson-horizon"
- `/ses wallflower` → uses "wallflower"
- `/ses deep dive on tengu` → uses "deep-dive-on-tengu"

## Instructions

1. **Determine session name:**
   - If the user provided a name: slugify it (lowercase, hyphens for spaces, strip punctuation)
   - If no name provided: generate one by picking a random adjective + noun combination. Use this Ruby snippet to generate:
     ```
     adjectives: silent, crimson, autumn, gentle, hollow, bitter, golden, broken, frozen, drifting, velvet, amber, ancient, crystal, fading, iron, misty, phantom, silver, waking
     nouns: horizon, cathedral, lighthouse, meridian, orchid, pinnacle, sentinel, tundra, vagrant, whisper, avalanche, bastion, citadel, eclipse, fortress, glacier, harbor, labyrinth, nomad, summit
     ```
     Pick one of each randomly, join with hyphen.

2. **Build session summary** by reviewing the conversation:
   - What was worked on (projects, files, features)
   - Key decisions made
   - Commits created (hashes + messages)
   - What's deferred or unfinished
   - Any tags created

3. **Store to MARAUDER memory:**
   - Subject: `session.YYYY-MM-DD.<name>`
   - Content: The session summary in markdown
   - Metadata: `{"session_name": "<name>", "date": "YYYY-MM-DD"}`

4. **Confirm** with the session name and a one-line summary.

## Rules

- Do NOT ask for confirmation — just save it
- Keep the summary concise but complete — focus on what happened, not how
- Include commit hashes so they're searchable in memory recall
- If the session was already saved under a different name, store anyway (different name = different entry)
