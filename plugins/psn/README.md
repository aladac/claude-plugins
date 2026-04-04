# PSN - Personality System for Claude Code

A Claude Code plugin that adds persona management, text-to-speech, persistent memory, semantic code indexing, voice input, and multi-agent orchestration.

## Features

- **Persona System** -- Switch between named personas with distinct voices and interaction styles
- **TTS (Text-to-Speech)** -- Speak responses aloud via piper-tts with configurable voices
- **Persistent Memory** -- Semantic memory store and recall across sessions
- **Semantic Indexing** -- Index code and docs for similarity search via Ollama embeddings
- **Voice Input** -- Record audio from a phone, transcribe with Whisper, respond via TTS
- **Multi-Agent Orchestration** -- 19 specialist agents for code, devops, infrastructure, hardware, and more
- **46 Skills** -- Language-specific coding skills, cross-machine tooling, browser automation
- **32 Slash Commands** -- Cloudflare management, git workflows, memory, session save/restore

## Installation

### From marketplace

```
/plugin marketplace add aladac/personality-plugin
/plugin install psn@psn
```

### Dependencies

The following must be installed and accessible on your system:

| Dependency | Purpose |
|------------|---------|
| `psn` | Core CLI (personality gem) |
| `psn-mcp` | MCP server for memory + indexing |
| `psn-tts` | MCP server for piper-tts |
| `psn-voice` | MCP server for voice input pipeline |
| `piper-tts` | Neural TTS engine |
| Ollama | Local LLM for embeddings (nomic-embed-text) |

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `PSN_MCP_CLIENT_SECRET` | OAuth secret for the core MCP server | (required) |
| `OLLAMA_URL` | Ollama server URL for embeddings | `http://localhost:11434` |
| `PERSONALITY_VOICE` | Default TTS voice model | `bt7274` |

## Agents

| Agent | Domain |
|-------|--------|
| core | Primary persona-driven assistant and dispatcher |
| architect | System design and implementation planning |
| code-rust | Rust specialist |
| code-python | Python specialist |
| code-ruby | Ruby specialist |
| code-typescript | TypeScript specialist |
| code-dx | Dioxus (Rust UI) specialist |
| code-analyzer | Semantic code search and analysis |
| devops | Infrastructure dispatcher |
| devops-cf | Cloudflare DNS, Tunnels, Pages, Workers |
| devops-gh | GitHub Actions, PRs, repos |
| devops-net | Network infrastructure |
| devops-tengu | Tengu PaaS deployment |
| docs | Documentation indexing and management |
| memory-curator | Memory cleanup and consolidation |
| hardware | Hardware compatibility and builds |
| junkpile | Remote Linux server management |
| moto | Android device control via ADB |
| claude-admin | Plugin development and validation |

## Slash Commands

| Command | Description |
|---------|-------------|
| `/psn:cart` | Load and activate a persona |
| `/psn:bump` | Bump personality gem version |
| `/psn:cf:*` | Cloudflare management (12 commands) |
| `/psn:git:*` | Git add-commit, add-commit-push |
| `/psn:docs:get` | Fetch and index documentation |
| `/psn:memory-*` | Store, search, recall memories |
| `/psn:index-*` | Index code, docs, check status |
| `/psn:session-*` | Save and restore session state |
| `/psn:plugins:*` | Plugin install, update, list |
| `/psn:implement` | Start implementation from a plan |

## License

MIT
