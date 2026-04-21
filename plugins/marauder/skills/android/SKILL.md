---
name: Android ADB
description: |
  Use for Android device operations via ADB on the Moto G52. Accessible via WiFi (192.168.88.155:5555) or USB through junkpile. Screenshot capture, input automation, app management, file transfer, and device control.

  <example>
  Context: User wants a phone screenshot
  user: "take a screenshot of the moto"
  </example>

  <example>
  Context: User wants to install an app
  user: "install this APK on the phone"
  </example>
---

# Android ADB Operations

The Moto G52 is accessible via two methods. **Prefer WiFi** for simplicity.

## ADB Command Patterns

### WiFi ADB (Preferred)

```bash
# Connect if needed
adb connect 192.168.88.155:5555

# Run commands directly
adb -s 192.168.88.155:5555 <command>
```

### USB via junkpile (Fallback)

```bash
# Route through junkpile via SSH
ssh j "export PATH=\$PATH:/home/linuxbrew/.linuxbrew/bin && adb <command>"
```

## Quick Reference

### Screenshot

Use the script — single command, handles ADB connect + screencap + validation:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/android/moto-screenshot.sh /tmp/moto_screen.png
```

Then read the image with the Read tool to view it. Do NOT dispatch an agent for this.

```bash
# With timestamp
bash ${CLAUDE_PLUGIN_ROOT}/skills/android/moto-screenshot.sh "/tmp/moto_$(date +%Y%m%d_%H%M%S).png"
```

### Screen Recording

```bash
# Start recording (Ctrl+C or timeout to stop)
adb -s 192.168.88.155:5555 shell screenrecord --time-limit 30 /sdcard/recording.mp4

# Retrieve recording
adb -s 192.168.88.155:5555 pull /sdcard/recording.mp4 /tmp/
```

### Input Simulation

```bash
# Tap at coordinates
adb -s 192.168.88.155:5555 shell input tap 540 1200

# Swipe (x1 y1 x2 y2 duration_ms)
adb -s 192.168.88.155:5555 shell input swipe 540 1800 540 600 300

# Type text
adb -s 192.168.88.155:5555 shell input text 'hello'

# Key events
adb -s 192.168.88.155:5555 shell input keyevent KEYCODE_HOME
adb -s 192.168.88.155:5555 shell input keyevent KEYCODE_BACK
adb -s 192.168.88.155:5555 shell input keyevent KEYCODE_POWER
```

### Key Codes

| Code | Action |
|------|--------|
| `KEYCODE_HOME` (3) | Home button |
| `KEYCODE_BACK` (4) | Back button |
| `KEYCODE_POWER` (26) | Power button |
| `KEYCODE_VOLUME_UP` (24) | Volume up |
| `KEYCODE_VOLUME_DOWN` (25) | Volume down |
| `KEYCODE_ENTER` (66) | Enter key |
| `KEYCODE_WAKEUP` (224) | Wake screen |
| `KEYCODE_SLEEP` (223) | Sleep screen |

### Screen Coordinates (1080x2400)

| Location | X | Y |
|----------|---|---|
| Center | 540 | 1200 |
| Top center | 540 | 200 |
| Bottom center | 540 | 2200 |
| Nav: Back | 180 | 2350 |
| Nav: Home | 540 | 2350 |
| Nav: Recent | 900 | 2350 |

### App Management

```bash
# List user apps
adb -s 192.168.88.155:5555 shell pm list packages -3

# Install APK
adb -s 192.168.88.155:5555 install /path/to/app.apk

# Uninstall
adb -s 192.168.88.155:5555 uninstall <package.name>

# Force stop app
adb -s 192.168.88.155:5555 shell am force-stop <package.name>

# Clear app data
adb -s 192.168.88.155:5555 shell pm clear <package.name>

# Launch app
adb -s 192.168.88.155:5555 shell monkey -p <package.name> 1
```

### File Transfer

```bash
# Push to device (direct via WiFi)
adb -s 192.168.88.155:5555 push /local/file.txt /sdcard/

# Pull from device
adb -s 192.168.88.155:5555 pull /sdcard/file.txt /local/
```

### Device Status

```bash
# Battery level
adb -s 192.168.88.155:5555 shell dumpsys battery | grep level

# Current activity/focus
adb -s 192.168.88.155:5555 shell dumpsys window | grep mCurrentFocus

# Memory info
adb -s 192.168.88.155:5555 shell cat /proc/meminfo | head -5

# Storage
adb -s 192.168.88.155:5555 shell df -h /data
```

### Logcat

```bash
# Live log (errors only)
adb -s 192.168.88.155:5555 logcat *:E

# Dump and filter
adb -s 192.168.88.155:5555 logcat -d | grep -i error

# By package
adb -s 192.168.88.155:5555 logcat --pid=$(adb -s 192.168.88.155:5555 shell pidof <package>) -d
```

### Wake and Unlock

```bash
# Wake screen
adb -s 192.168.88.155:5555 shell input keyevent KEYCODE_WAKEUP

# Swipe to unlock (if no PIN)
adb -s 192.168.88.155:5555 shell input swipe 540 2000 540 1000 300

# Combined
adb -s 192.168.88.155:5555 shell 'input keyevent KEYCODE_WAKEUP && sleep 0.5 && input swipe 540 2000 540 1000 300'
```

### Open URLs/Intents

```bash
# Open URL in browser
adb -s 192.168.88.155:5555 shell am start -a android.intent.action.VIEW -d 'https://example.com'

# Open settings
adb -s 192.168.88.155:5555 shell am start -a android.settings.SETTINGS

# Make call (opens dialer)
adb -s 192.168.88.155:5555 shell am start -a android.intent.action.DIAL -d tel:5551234
```
