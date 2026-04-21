#!/usr/bin/env bash
#
# junkpile-server-mode.sh
#
# Switches junkpile from graphical desktop to server mode by stopping
# GDM, GNOME Shell, X11, and related desktop services. Frees GPU memory
# for compute workloads (Ollama, ComfyUI, etc.).
#
# Uses MQTT mesh for fire-and-forget commands, SSH for status queries.

set -euo pipefail

MESH="marauder mesh send junkpile exec"
HOST="j"

echo "=== Junkpile: Switching to Server Mode ==="
echo ""

# Check if already in server mode (needs stdout → SSH)
current_target=$(ssh "$HOST" "systemctl get-default")
if [ "$current_target" = "multi-user.target" ]; then
    gdm_active=$(ssh "$HOST" "systemctl is-active gdm.service 2>/dev/null || true")
    if [ "$gdm_active" != "active" ]; then
        echo "Already in server mode (multi-user.target, GDM stopped)."
        exit 0
    fi
    echo "Default target is multi-user but GDM is still running. Proceeding..."
fi

# Set default target + stop all desktop services in one remote command (MQTT)
echo "[1/2] Stopping desktop services via mesh..."
$MESH '{"command":"sudo systemctl set-default multi-user.target && sudo systemctl stop gdm.service gnome-remote-desktop.service colord.service switcheroo-control.service power-profiles-daemon.service accounts-daemon.service cups.service cups-browsed.service 2>/dev/null; echo done"}'

# Wait for services to actually stop
sleep 3

# Verify GPU is freed (needs stdout → SSH)
echo "[2/2] Verifying GPU state..."
echo ""
ssh "$HOST" "nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader"
echo ""
echo "GPU processes remaining:"
ssh "$HOST" "nvidia-smi pmon -c 1 2>/dev/null | grep -v '^#' || echo '  (none)'"

echo ""
echo "=== Server mode active ==="
echo "Desktop services stopped. GPU memory freed for compute."
