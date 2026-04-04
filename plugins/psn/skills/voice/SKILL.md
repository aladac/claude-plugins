---
name: Voice Pipeline
description: |
  Voice-to-Claude pipeline. Record from Moto G52 phone, transcribe via Whisper on junkpile, send to Claude, respond via TTS. Use when the user wants to speak to Claude or use voice commands.

  <example>
  Context: User wants to use voice input
  user: "record my voice"
  </example>

  <example>
  Context: User wants to check voice pipeline status
  user: "is the voice pipeline working?"
  </example>
---

# Voice Pipeline

Full voice interaction flow: Phone mic -> Whisper STT -> Claude -> Piper TTS

## MCP Tools

### voice_ask (Full Pipeline)

Record, transcribe, and get Claude response in one call:

```
voice_ask(duration: 8, speak_response: true)
```

Returns: `{transcript: "...", response: "...", success: true}`

### voice_record

Record audio from the phone only:

```
voice_record(duration: 10, output_path: "/tmp/voice.wav")
```

### voice_transcribe

Transcribe an existing audio file:

```
voice_transcribe(audio_path: "/tmp/voice.wav", model: "small")
```

Models: `tiny`, `base`, `small`, `medium`, `large`

### voice_status

Check pipeline health:

```
voice_status()
```

Returns connectivity status for phone (ADB), junkpile, Whisper, Claude.

## Architecture

```
[Moto G52]                    [fuji]                     [junkpile]
    |                            |                            |
    | ADB WiFi                   |                            |
    | 192.168.88.155:5555        |                            |
    |                            |                            |
    +-- termux-microphone-record |                            |
    |                            |                            |
    +---------> voice.wav ------>+--------> scp ------------->+
                                 |                            |
                                 |                   Whisper STT
                                 |                            |
                                 |                   Claude CLI
                                 |                            |
                                 +<-------- response ---------+
                                 |
                            Piper TTS
                                 |
                            [Speaker]
```

## Prerequisites

| Component | Location | Status |
|-----------|----------|--------|
| Termux + termux-api | Moto G52 | Required |
| ADB over WiFi | 192.168.88.155:5555 | Required |
| Whisper | junkpile ~/.local/bin/whisper | Required |
| Claude CLI | junkpile /home/linuxbrew/.linuxbrew/bin/claude | Required |
| Piper TTS | fuji (psn-mcp --mode local) | Required |

## Quick Test

```bash
# Check status
mcp__plugin_psn_local__voice_status()

# Full voice interaction (8 seconds)
mcp__plugin_psn_local__voice_ask(duration: 8)
```

## Troubleshooting

### ADB Connection Lost

```bash
adb connect 192.168.88.155:5555
```

### Whisper Slow First Run

First transcription downloads the model (~500MB for small). Subsequent runs are fast.

### Empty Transcription

- Check audio was actually recorded (file size > 0)
- Ensure microphone permission granted to Termux
- Try speaking louder/closer to phone
