---
name: Text-to-Speech
description: |
  This skill should be used when speaking text aloud, managing TTS voices, or controlling audio playback. Triggers on requests to speak, read aloud, announce, use voice output, or manage TTS settings.

  <example>
  Context: User wants audio feedback
  user: "Say hello"
  </example>

  <example>
  Context: User wants to change voice
  user: "Switch to a different voice"
  </example>

  <example>
  Context: User wants to stop audio
  user: "Stop talking"
  </example>

  <example>
  Context: User wants to hear available voices
  user: "What voices do you have?"
  </example>
version: 1.0.0
---

# Tools Reference

## MCP Tools (psn speech server)
| Tool | Purpose |
|------|---------|
| `mcp__plugin_psn_speech__speak` | Speak text aloud (async playback) |
| `mcp__plugin_psn_speech__stop` | Stop currently playing audio |
| `mcp__plugin_psn_speech__voices` | List installed voice models |
| `mcp__plugin_psn_speech__current` | Show active voice and status |
| `mcp__plugin_psn_speech__download` | Download a piper voice from HuggingFace |
| `mcp__plugin_psn_speech__test` | Test a voice with sample text (sync) |

---

# Text-to-Speech

Voice output using Piper TTS via the psn speech MCP server.

## Architecture

- **Engine**: Piper TTS (local, fast neural TTS)
- **Transport**: MCP stdio server (`psn-tts`)
- **Voices**: ONNX models stored locally
- **Playback**: Async via system audio

## Quick Start

### Speak Text
```
mcp__plugin_psn_speech__speak(text: "Hello, I'm ready to help.")
```

### Stop Playback
```
mcp__plugin_psn_speech__stop()
```

### Check Current Voice
```
mcp__plugin_psn_speech__current()
```

## Voice Management

### List Installed Voices
```
mcp__plugin_psn_speech__voices()
```

Returns installed voice models with:
- Name (e.g., `en_US-lessac-medium`)
- Language
- Quality level

### Download New Voice
```
mcp__plugin_psn_speech__download(voice: "en_US-lessac-medium")
```

Downloads from HuggingFace's Piper voice repository.

### Test a Voice
```
mcp__plugin_psn_speech__test(voice: "en_US-lessac-medium")
```

Speaks sample text and waits for completion (synchronous).

## Voice Naming Convention

Piper voices follow the pattern:
```
{language}_{region}-{name}-{quality}
```

Examples:
| Voice | Description |
|-------|-------------|
| `en_US-lessac-medium` | US English, Lessac, medium quality |
| `en_GB-alan-medium` | British English, Alan voice |
| `en_US-amy-low` | US English, Amy, low quality (faster) |
| `en_US-ryan-high` | US English, Ryan, high quality |

Quality levels:
- `low` - Fastest, smaller model
- `medium` - Balanced (recommended)
- `high` - Best quality, larger model

## Configuration

The active voice is set via environment variable:
```
PERSONALITY_VOICE=bt7274
```

Or in `.mcp.json`:
```json
{
  "mcpServers": {
    "speech": {
      "command": "psn-tts",
      "env": {
        "PERSONALITY_VOICE": "bt7274"
      }
    }
  }
}
```

## Playback Behavior

### Async by Default
`speak()` starts playback and returns immediately. Audio plays in background.

### Sync Testing
`test()` blocks until audio completes. Use for voice previews.

### Stopping
`stop()` immediately halts any playing audio.

### Queue Behavior
New `speak()` calls while audio is playing will queue. Use `stop()` first if you need to interrupt.

## Best Practices

1. **Keep text concise** - Long text takes time to synthesize
2. **Use stop() before new speech** - Avoid overlapping audio
3. **Test voices before switching** - Ensure quality meets needs
4. **Match voice to persona** - Different voices for different contexts
5. **Consider latency** - First synthesis may be slower (model loading)

## Common Patterns

### Notification on Task Complete
```python
# After completing a long task
mcp__plugin_psn_speech__speak(text: "Build completed successfully")
```

### Voice Selection Flow
```python
# List available voices
voices = mcp__plugin_psn_speech__voices()

# Test one
mcp__plugin_psn_speech__test(voice: "en_US-ryan-high")

# If satisfied, update config to use it
```

### Interrupt and Speak
```python
mcp__plugin_psn_speech__stop()  # Stop any current speech
mcp__plugin_psn_speech__speak(text: "Urgent: deployment failed")
```

## Troubleshooting

### No Audio
- Check system audio output
- Verify voice model is installed: `voices()`
- Check current voice status: `current()`

### Slow First Synthesis
- Normal - model loads on first use
- Subsequent calls are faster

### Voice Not Found
- Download with `download(voice: "voice-name")`
- Check exact spelling from HuggingFace

## Related

- Persona system uses TTS for voice output
- Session hooks can trigger speech on events
- Memory stores voice preferences
