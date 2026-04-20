---
name: kitty-mesh
description: Send kitten @ commands to remote Kitty terminals on mesh nodes via MQTT. Use when the user wants to control a Kitty terminal on another machine (junkpile, moto, tachikoma) without SSH.
---

# Kitty Mesh — Cross-Node Terminal Control

Send `kitten @` commands to any MARAUDER mesh node's Kitty terminal via MQTT.

## When To Use

- User wants to read/write terminal content on another node
- Controlling Kitty panes on moto (SERE display), junkpile, or tachikoma from fuji
- SSH is unavailable or unreliable (sign_and_send_pubkey errors)
- Any `kitten @` operation on a remote node

## MCP Tool

Use `mesh_kitty` MCP tool directly:

| Parameter | Required | Description |
|-----------|----------|-------------|
| `node` | yes | Target node: fuji, junkpile, moto, tachikoma |
| `subcommand` | yes | Kitten subcommand: ls, get-text, send-text, set-font-size, set-colors, etc. |
| `args` | no | Additional arguments for the subcommand |

## CLI

```bash
marauder mesh kitty <node> <subcommand> [args...]
```

## Examples

```bash
# List windows/tabs on moto
marauder mesh kitty moto ls

# Read SERE display content
marauder mesh kitty moto get-text

# Type a command into junkpile terminal
marauder mesh kitty junkpile send-text "htop\n"

# Change font size on tachikoma
marauder mesh kitty tachikoma set-font-size 18

# Set colors on moto SERE display
marauder mesh kitty moto set-colors foreground=#00ff41 background=#0a0a0a

# Display an image on moto via icat
marauder mesh kitty moto kitten icat /tmp/image.png
```

## How It Works

1. Constructs `kitten @ --to unix:<socket> <subcommand> <args>`
2. Sends as M01 exec command to target node via MQTT
3. Target node's mesh daemon runs the command locally
4. Result returned on the node's log topic

Socket path is auto-resolved per platform (Termux path on Android, /tmp/mykitty elsewhere).

## Nodes

| Node | Platform | Kitty Use |
|------|----------|-----------|
| fuji | macOS | Primary workstation |
| junkpile | Linux x86 | Compute node |
| moto | Android/Termux | SERE mobile display |
| tachikoma | RPi ARM | Edge sensor node |
