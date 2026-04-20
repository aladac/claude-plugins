---
description: "Store important insights to memory and create docs in appropriate place"
---

# Insight

Capture an important insight, decision, or learning — store it in MARAUDER memory AND write it to the appropriate documentation location.

## Arguments

The insight topic or content after `/insight`. Can be:
- A topic to extract from the current conversation: `/insight cloudflare field limitations`
- A direct statement: `/insight Cloudflare is garrison-only infrastructure, field platform must be fully autonomous`
- Empty — extract the most noteworthy insight from the recent conversation: `/insight`

## Instructions

1. **Identify the insight:**
   - If the user provided a topic: extract the relevant insight from the conversation, expanding with context
   - If the user provided a direct statement: use that as the core insight
   - If no argument: review the last ~10 exchanges and identify the most significant non-obvious insight, decision, or learning

2. **Classify the insight** — determine the best subject and doc location:

   | Type | Memory Subject | Doc Location |
   |------|---------------|--------------|
   | Architecture decision | `decision.<project>.<topic>` | `~/Projects/<project>/docs/decisions/` |
   | Technical insight | `insight.<topic>` | `~/Projects/marauder-hq/docs/insights/` |
   | User preference/workflow | `user.<topic>` | Agent memory markdown |
   | Project convention | `project.<name>.<topic>` | `~/Projects/<project>/docs/` |
   | Infrastructure | `infra.<topic>` | `~/Projects/marauder-hq/docs/infra/` |
   | EVE Online | `eve.<topic>` | `~/Projects/marauder-hq/docs/eve/` |
   | General reference | `reference.<topic>` | `~/Projects/marauder-hq/docs/reference/` |

3. **Store to MARAUDER memory:**
   - Use `memory_store` with the classified subject
   - Content should be concise but self-contained — readable without conversation context
   - Include **Why** and **Implications** where relevant

4. **Write the doc file:**
   - Create the target directory if it doesn't exist
   - Filename: slugified topic, e.g. `cloudflare-field-limitations.md`
   - Format:
     ```markdown
     # Title

     **Date:** YYYY-MM-DD
     **Context:** one-line context

     ## Insight

     The core insight in 2-3 sentences.

     ## Detail

     Supporting detail, reasoning, implications.

     ## References

     Links to related memories, docs, or external sources.
     ```
   - If the file already exists, append a new section with the date rather than overwriting

5. **Speak a one-line confirmation** of what was stored and where.

## Rules

- Do NOT ask for confirmation — just store it
- Keep insights **non-obvious** — don't store things derivable from code or docs
- The memory entry should be self-contained — someone recalling it in 6 months should understand it without context
- Prefer updating existing insights over creating duplicates — check memory first
- If the insight is about a specific project and that project has a `docs/` directory, put it there. Otherwise default to `marauder-hq/docs/`
