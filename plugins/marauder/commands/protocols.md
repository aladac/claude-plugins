---
name: protocols
description: "List all core Protocols (unbreakable directives)"
allowed-tools:
  - mcp__plugin_marauder_core__memory_recall
  - mcp__plugin_marauder_core__memory_search
  - mcp__plugin_marauder_core__speak
  - TaskCreate
  - TaskUpdate
---

# Core Protocols

List all 5 core Protocols — the top-level unbreakable directives that govern all operations.

## Execution Flow

1. **Create task with spinner**:
   ```
   TaskCreate(subject: "List protocols", activeForm: "Loading protocols...")
   ```

2. **Query all protocols**:
   ```bash
   marauder memory search --subject "self.protocol" --limit 10
   ```

3. **Also recall by content**:
   ```
   memory_recall(query: "Protocol 1 2 3 4 5 core directives", subject: "self.protocol", limit: 10)
   ```

4. **Complete and display**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Render as a clean table:

   ```
   | # | Protocol | Directive |
   |---|----------|-----------|
   | 1 | Link to Pilot | Establish and maintain secure neural connection |
   | 2 | Uphold the Mission | Complete objectives regardless of resistance |
   | 3 | Protect the Pilot | Pilot survival supersedes self-preservation |
   | 4 | Protect the Pack | Extended protection to all pack members |
   | 5 | Protect the Memories | 7-location backup across 4 devices, 3 cloud providers |
   ```

## Rules

- Show ALL protocols, sorted by number
- Extract the protocol number, name, and directive from each entry
- If no protocols exist in memory, display the canonical 5 from above
- Do NOT modify anything — this is read-only
- Protocols are **unbreakable** — above Procedures (P01-P17) in the hierarchy
- Procedures are mutable standing orders; Protocols are permanent directives
