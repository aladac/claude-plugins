# Moto G52 Capability Analysis Report

**Date**: 2026-04-08
**Purpose**: SERE project -- standalone MARAUDER edge node capability assessment
**Serial**: ZY22HTMMQG
**Connection**: USB via junkpile (ADB), WiFi ADB 192.168.88.155:5555
**Orientation**: Landscape (rotation 3), mounted on monitor, front camera facing pilot

---

## 1. Device Identity

| Property | Value |
|----------|-------|
| Model | Motorola Moto G52 (rhode) |
| OS | LineageOS 23.2 (2026-03-21 nightly) |
| Android | 16 (API 36) |
| Build ID | BP4A.251205.006 |
| Kernel | 4.19.325-cip128-st12-perf |
| Architecture | arm64-v8a, armeabi-v7a, armeabi |
| SELinux | Enforcing |
| Encryption | Encrypted |
| Root | Magisk 30.7 (su confirmed uid=0, context u:r:magisk:s0) |
| Uptime at probe | 11 days, 15h44m |

---

## 2. Hardware Resources

### CPU -- Qualcomm Snapdragon 680 (Kryo 265)

| Cluster | Cores | Frequencies (MHz) | Governor |
|---------|-------|--------------------|----------|
| Performance (A73) | cpu0-3 | 300, 691, 941, 1190, 1517, 1805, **1901** | schedutil |
| Efficiency (A53) | cpu4-7 | 300, 806, 1056, 1344, 1766, 2208, **2400** | schedutil |

Current load at probe: 0.00, 0.00, 0.00 (idle)

### Memory

| Metric | Value |
|--------|-------|
| Total RAM | 5,816 MB (~5.5 GB) |
| Free | 370 MB |
| Available | 3,202 MB |
| Cached | 2,901 MB |
| Swap cached | 24 KB |

### Storage

| Partition | Size | Used | Available | Use% |
|-----------|------|------|-----------|------|
| /data | 229 GB | 3.9 GB | 225 GB | 2% |

### Battery

| Metric | Value |
|--------|-------|
| Level | 100% |
| Status | Full (status 5) |
| Power source | USB (500 mA) |
| Voltage | 4,408 mV |
| Temperature | 27.0 C |
| Technology | Li-ion |
| Capacity | 5,000 mAh |
| Health | Good |

### Display

| Property | Value |
|----------|-------|
| Panel | 6.6" OLED |
| Resolution | 1080x2400 |
| Density | 400 DPI |
| Refresh rate | 90 Hz |
| Current state | ON |
| Auto-rotate | OFF |
| User rotation | 3 (landscape) |
| Screen timeout | 60,000 ms (1 min) |

### Brightness Control

| Operation | Status |
|-----------|--------|
| Read brightness | YES (settings get system screen_brightness) |
| Set brightness | YES (settings put system screen_brightness 0-255) |
| Brightness mode | 0 (manual) |
| Tested values | 50 -> 128 -> 200 (all confirmed) |

---

## 3. Thermal Monitoring

44 thermal zones available. Key readings at probe (millidegrees C):

| Zone | Temp (C) | Notes |
|------|----------|-------|
| battery | 27.0 | Battery cell |
| front_temp | 27.2 | Front surface |
| back_temp | 27.2 | Back surface |
| cpu-1-0-usr | 28.9 | Performance core |
| cpuss-2-usr | 29.7 | Highest CPU cluster |
| gpu-usr | 28.1 | GPU |
| display-usr | 28.9 | Display |
| wlan-usr | 28.1 | WiFi module |
| camera-usr | 28.1 | Camera ISP |
| pm6125-tz | 37.0 | PMIC (highest overall) |

All temperatures nominal. Device is cool and idle.

---

## 4. Network

### WiFi

| Property | Value |
|----------|-------|
| SSID | okinawa |
| IP | 192.168.88.155/24 |
| IPv6 | fe80::aa54:a615:7dde:c229 (link-local) |
| MAC | B0:4A:B4:7E:86:87 |
| BSSID | 50:91:E3:BC:8C:B6 |
| Frequency | 5240 MHz (5 GHz) |
| Standard | 802.11ac |
| Tx speed | 263 Mbps |
| Max Tx | 433 Mbps |
| RSSI | -59 dBm |
| Score | 71 |
| Internet | YES (8.8.8.8 ping 23.5 ms) |

### Cellular

| Property | Value |
|----------|-------|
| Carrier | T-Mobile.pl (MCC 260, MNC 02) |
| Technology | LTE (Band 8, EARFCN 3686) |
| Registration | HOME (voice + data) |
| LTE RSRP | -87 dBm |
| LTE RSRQ | -19 dB |
| LTE RSSNR | 3 dB |
| Signal level | 4 (strong) |
| Mobile data | OFF (wifi preferred, IWLAN active) |

### Bluetooth

| Property | Value |
|----------|-------|
| State | ON |

---

## 5. Cameras

### Camera Hardware Summary

| ID | Facing | Max Resolution | Sensor Size (mm) | Focal Length (mm) | Capabilities |
|----|--------|---------------|-------------------|-------------------|--------------|
| 0 | Back (main) | 4080x2296 (~9.4 MP) | 5.22 x 3.93 | 4.27 | Flash, RAW, burst, manual, hi-speed video |
| 1 | **Front** | **2304x1728 (~4 MP)** | **4.61 x 3.46** | **3.27** | **RAW, burst, manual sensor** |
| 2 | Back (macro) | 1600x1200 (2 MP) | 2.80 x 2.10 | 2.07 | Flash, RAW, burst, manual |
| 3 | Back (depth) | 3264x2448 (8 MP) | 3.66 x 2.74 | 1.66 | Flash, RAW, burst, manual |
| 4 | Back (logical) | 4080x2296 (~9.4 MP) | 5.22 x 3.93 | 4.27 | Multi-camera, hi-speed, everything |

### Front Camera Direct Capture (SERE Primary)

| Method | Status | Notes |
|--------|--------|-------|
| `termux-camera-photo -c 1` | **YES** | 2.7 MB JPEG, 2304x1728, includes EXIF + GPS |
| Camera intent + tap | YES | Requires screen interaction, less reliable |
| V4L2 direct (`/dev/video*`) | NO | v4l2-ctl not available, devices owned by system:camera |
| Root camera access | PARTIAL | /dev/video0-2,32,33 exist + 20 v4l-subdev nodes |

**Verified**: `termux-camera-photo -c 1 <output.jpg>` produces valid JPEG from front camera via Termux API. Photo confirmed -- shows room from mounted position.

### Camera Capture Command (via ADB)

```bash
adb shell 'su -c "run-as com.termux files/usr/bin/termux-camera-photo -c 1 /data/data/com.termux/files/home/capture.jpg"'
# Then copy out:
adb shell 'su -c "cp /data/data/com.termux/files/home/capture.jpg /sdcard/capture.jpg"'
adb pull /sdcard/capture.jpg
```

---

## 6. Sensors

### Physical Sensors

| Sensor | Chip | Vendor | Type ID |
|--------|------|--------|---------|
| Accelerometer | bmi3x0 | BOSCH | 1 |
| Magnetometer | mmc56x3x | MEMSIC | 2 |
| Gyroscope | bmi3x0 | BOSCH | 4 |
| Ambient Light | mn | Eminent | 5 |
| Proximity | mn | Eminent | 8 |
| CapSense (x4) | Ch0-Ch4 | Awinic | 65552 |

### Computed/Fusion Sensors

| Sensor | Provider | Type ID |
|--------|----------|---------|
| Orientation | Qualcomm | 3 |
| Gravity | Qualcomm | 9 |
| Linear Acceleration | Qualcomm | 10 |
| Rotation Vector | Qualcomm | 11 |
| Geomagnetic Rotation | Qualcomm | 20 |
| Game Rotation Vector | Qualcomm | 15 |
| Gyroscope Uncalibrated | BOSCH | 16 |
| Magnetometer Uncalibrated | MEMSIC | 14 |
| Accelerometer Uncalibrated | BOSCH | 35 |
| Significant Motion | Qualcomm | 17 |
| Step Detector | Qualcomm | 18 |
| Step Counter | Qualcomm | 19 |
| Stationary Detect | Qualcomm | 29 |
| Motion Detect | Qualcomm | 30 |
| Device Orientation | Motorola | 27 |

### Motorola-Specific Sensors

| Sensor | Type |
|--------|------|
| Double-Tap Gesture | 65566 |
| Flat Up | 65537 |
| Flat Down | 65538 |
| Stowed | 65539 |
| Camera Gesture | 65540 |
| ChopChop | 65546 |
| Moto Glance | 65548 |
| Lift to Silence | 65553 |
| Flip to Mute | 65554 |
| Lift to View | 65556 |

### Sensor Access

| Method | Status |
|--------|--------|
| `termux-sensor` | Available (Termux API) |
| `dumpsys sensorservice` | YES |
| Direct `/dev/` access | Requires root + camera group |

---

## 7. Audio

| Property | Value |
|----------|-------|
| Sound card | bengal-awinic-snd-card |
| Microphone recording | `termux-microphone-record` available |
| TTS | `termux-tts-speak` available |
| Media playback | `termux-media-player` available |
| Volume control | `termux-volume` available |

---

## 8. Display Push Capabilities

| Capability | Method | Status |
|------------|--------|--------|
| Open URL | `am start -a VIEW -d <url>` | YES |
| Show toast | `termux-toast "message"` | YES |
| Notification | `termux-notification` | YES |
| Set brightness | `settings put system screen_brightness <0-255>` | YES |
| Set wallpaper | `termux-wallpaper` | Available |
| Wake screen | `input keyevent KEYCODE_WAKEUP` | YES |
| Screenshot | `screencap -p` via adb exec-out | YES |
| Screen record | `screenrecord` (max 180s) | YES |
| Clipboard | `termux-clipboard-set/get` | Available |
| Open file viewer | `am start -a VIEW -d file:// -t <mime>` | YES |
| Display density | `wm density <dpi>` | YES (default 400) |
| Screen size | `wm size <WxH>` | YES (default 1080x2400) |

---

## 9. Root Capabilities (Magisk 30.7)

| Capability | Status | Notes |
|------------|--------|-------|
| su access | YES | uid=0, context u:r:magisk:s0 |
| SELinux | Enforcing | Can read but not easily toggle |
| /data access | YES | Full filesystem read/write |
| Kernel modules | 20+ loaded | wlan, fingerprint, audio, charger, vibrator |
| CPU freq control | YES | Read scaling_available_frequencies, could write governor |
| Thermal zone read | YES | 44 zones readable |
| Process namespace | Partial | nsenter had issues, but su -c run-as works |
| App data access | YES | Can read/write any app's /data/data |

---

## 10. Installed Apps

### User Apps

| Package | App | Notes |
|---------|-----|-------|
| `com.termux` | Termux | Full Linux environment |
| `com.termux.api` | Termux:API | Hardware access bridge |
| `com.topjohnwu.magisk` | Magisk | Root manager |
| `org.fdroid.fdroid` | F-Droid | App store |
| `org.videolan.vlc` | VLC | Media player |
| `org.thoughtcrime.securesms` | Signal | Messaging |

### Camera Apps (System)

| Package | App |
|---------|-----|
| `org.lineageos.aperture` | LineageOS Aperture |
| `com.google.android.apps.googlecamera.fishfood` | Google Camera (dogfood) |

---

## 11. Termux Environment

### Key Packages Installed

Full development toolchain available:

| Category | Tools |
|----------|-------|
| Languages | Python 3.13, Bash, Dash |
| Compilers | Clang 21, GCC (cross), LLVM full suite |
| Build | Make, CMake (implied by clang toolchain) |
| Networking | curl, ssh, scp, sftp, telnet, ftp, ping, drill |
| VCS | Git (via git-clang-format at minimum) |
| Editors | nano |
| Crypto | GPG, Kerberos (full MIT krb5 suite) |
| Compression | gzip, bzip2, xz, zstd, zip |
| Package mgmt | apt, dpkg, pkg |
| System | coreutils, findutils, procps, util-linux |

### Termux API Commands (72 commands)

Full hardware access layer available:

| Category | Commands |
|----------|----------|
| Camera | `termux-camera-info`, `termux-camera-photo` |
| Audio | `termux-microphone-record`, `termux-media-player`, `termux-tts-speak`, `termux-audio-info`, `termux-volume` |
| Sensors | `termux-sensor`, `termux-location` |
| Display | `termux-toast`, `termux-notification`, `termux-brightness`, `termux-wallpaper`, `termux-torch` |
| Communication | `termux-sms-send`, `termux-sms-inbox`, `termux-telephony-call`, `termux-telephony-cellinfo`, `termux-telephony-deviceinfo` |
| Input | `termux-dialog`, `termux-fingerprint`, `termux-speech-to-text`, `termux-clipboard-get/set` |
| System | `termux-battery-status`, `termux-wifi-connectioninfo`, `termux-wifi-scaninfo`, `termux-vibrate`, `termux-wake-lock/unlock`, `termux-usb`, `termux-nfc`, `termux-infrared-transmit/frequencies` |
| Storage | `termux-saf-*` (8 commands), `termux-storage-get`, `termux-download`, `termux-share`, `termux-open` |
| Jobs | `termux-job-scheduler` |
| Contacts | `termux-contact-list`, `termux-call-log` |

---

## 12. SERE Edge Node Assessment

### Confirmed Capabilities for SERE

| Requirement | Capability | Method | Reliability |
|-------------|-----------|--------|-------------|
| Visual perception | Front camera capture | `termux-camera-photo -c 1` | HIGH -- 4MP, headless, no UI needed |
| Environmental sensing | Accel + Gyro + Mag + Light + Prox | `termux-sensor` or `dumpsys` | HIGH |
| Temperature monitoring | 44 thermal zones | sysfs direct read | HIGH |
| Network comms (WiFi) | 802.11ac, 5 GHz | Always connected | HIGH |
| Network comms (LTE) | T-Mobile.pl LTE Band 8 | Fallback available | MEDIUM (data off) |
| Audio input | Microphone | `termux-microphone-record` | HIGH |
| Audio output | Speaker + TTS | `termux-tts-speak` / `termux-media-player` | HIGH |
| Display output | OLED 1080x2400 | URL, toast, notifications, brightness | HIGH |
| GPS | Available | `termux-location` | UNTESTED |
| Flashlight/Torch | Available | `termux-torch` | UNTESTED |
| Vibration | Available | `termux-vibrate` | UNTESTED |
| NFC | Available | `termux-nfc` | UNTESTED |
| IR blaster | Available | `termux-infrared-transmit` | UNTESTED |
| SMS send/receive | Available | `termux-sms-send/inbox` | UNTESTED |
| Phone calls | Available | `termux-telephony-call` | UNTESTED |
| Bluetooth | ON | System-level | UNTESTED |
| Compute | 8-core ARM64, 5.5GB RAM, 225GB free | Native + Python | HIGH |
| Root access | Magisk 30.7 | su -c | HIGH |
| Remote control | ADB over USB + WiFi | Full shell + file transfer | HIGH |
| Uptime | 11+ days confirmed | Stable | HIGH |

### Limitations

| Limitation | Impact | Workaround |
|------------|--------|------------|
| No V4L2 userspace tools | Cannot stream video frames directly | Use termux-camera-photo for snapshots |
| SELinux enforcing | Some root operations restricted | Magisk handles most bypasses |
| Screen timeout 60s | Screen goes off quickly | `settings put system screen_off_timeout 2147483647` or `termux-wake-lock` |
| Camera photo not streamable | Single frame capture only | Repeated capture loop possible |
| Front camera orientation | Images rotated (landscape mount) | Post-process rotation or EXIF-aware display |
| Mobile data OFF | No LTE failover | `settings put global mobile_data 1` to enable |

### Recommended Quick Setup for SERE

```bash
# Prevent screen timeout
adb shell settings put system screen_off_timeout 2147483647

# Enable mobile data as failover
adb shell settings put global mobile_data 1

# Set fixed brightness for monitoring
adb shell settings put system screen_brightness 128

# Take wake lock to prevent deep sleep
adb shell run-as com.termux files/usr/bin/termux-wake-lock

# Verify front camera
adb shell 'su -c "run-as com.termux files/usr/bin/termux-camera-photo -c 1 /data/data/com.termux/files/home/test.jpg"'
```

---

## 13. Kernel Modules (Loaded)

| Module | Size | Used | Purpose |
|--------|------|------|---------|
| wlan | 6.2 MB | 0 | WiFi driver |
| rbs_fps_mmi | 29 KB | 2 | Fingerprint sensor |
| aw882xx_dlkm | 152 KB | 2 | Audio amplifier (Awinic) |
| aw9610x | 53 KB | 0 | CapSense touch |
| mmi_discrete_turbo_charger | 78 KB | 0 | Turbo charging |
| ldo_vibrator_mmi | 16 KB | 0 | Vibration motor |
| bq2597x_mmi_iio | 45 KB | 0 | Battery charger IC |
| sm5602_fg_mmi | 45 KB | 0 | Fuel gauge |
| bq2589x_charger | 45 KB | 0 | Charger controller |
| rouleur_dlkm | 74 KB | 1 | Audio codec |
| machine_dlkm | 119 KB | 0 | Audio machine driver |
| utags | 33 KB | 0 | Motorola partition tags |
| wl2866d | 16 KB | 0 | Camera PMIC |
| cci_intf | 16 KB | 0 | Camera CCI interface |
