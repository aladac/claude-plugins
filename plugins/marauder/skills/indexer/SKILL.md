---
name: Code Analysis
description: |
  Index codebases and docs for semantic search. Use to find implementations, search code patterns, or understand architecture across indexed projects.

  <example>
  Context: User wants to search code semantically
  user: "Find all places where we handle authentication"
  </example>

  <example>
  Context: User wants to index a project
  user: "Index this codebase so we can search it"
  </example>
version: 1.0.0
---

# Tools Reference

## MCP Tools (marauder server)
| Tool | Purpose |
|------|---------|
| `mcp__plugin_marauder_core__index_code` | Index source code files |
| `mcp__plugin_marauder_core__index_docs` | Index documentation |
| `mcp__plugin_marauder_core__index_search` | Semantic search indexed content |
| `mcp__plugin_marauder_core__index_status` | Check indexing status |
| `mcp__plugin_marauder_core__index_clear` | Clear index for project |

## Related Commands
| Command | Purpose |
|---------|---------|
| `/index:code` | Index a codebase |
| `/index:docs` | Index documentation |
| `/index:status` | Show indexing status |

## Related Agents
- `marauder:code-analyzer` - Deep code analysis with indexer

---

# Code Analysis

Guidance for semantic code analysis using the indexer.

## Index Architecture

The indexer uses:
- **Chunking**: Code split into ~2000 char overlapping chunks
- **Embeddings**: nomic-embed-text via Ollama
- **Storage**: SQLite + sqlite-vec
- **Search**: Vector distance for semantic matching

## Indexing Best Practices

### When to Index
- New project checkout
- After significant code changes
- Before deep code exploration

### What Gets Indexed
- Code files: `.py`, `.rs`, `.rb`, `.js`, `.ts`, `.go`, `.java`, `.c`, `.cpp`, `.h`
- Doc files: `.md`, `.txt`, `.rst`, `.adoc`

### Project Organization
- Index each project separately with meaningful names
- Re-index periodically to capture changes
- Clear stale indices to save space

## Search Strategies

### Finding Implementations
Query: "function that handles user authentication"
-> Returns code chunks with authentication logic

### Finding Patterns
Query: "error handling with retry logic"
-> Returns examples of retry patterns

### Understanding Architecture
Query: "main entry point and initialization"
-> Returns startup/main code

## Combining with Memory

After analysis, store findings:
```
Subject: project.{name}.architecture
Content: Summary of discovered architecture patterns
```

## Search Tips

1. Use natural language queries - embeddings understand semantics
2. Filter by project for focused results
3. Combine code and doc search for full context
4. Lower distance scores = better matches (sqlite-vec uses distance, not similarity)
