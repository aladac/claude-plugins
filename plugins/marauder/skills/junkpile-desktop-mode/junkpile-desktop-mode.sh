#!/usr/bin/env bash
#
# junkpile-desktop-mode.sh
#
# Switches junkpile back to graphical desktop mode by starting GDM,
# which brings up X11, GNOME Shell, and the full desktop environment.
#
# Uses MQTT mesh for fire-and-forget commands, SSH for status queries.

set -euo pipefail

MESH="marauder mesh send junkpile exec"
HOST="j"

echo "=== Junkpile: Switching to Desktop Mode ==="
echo ""

# Check if already in graphical mode (needs stdout → SSH)
current_target=$(ssh "$HOST" "systemctl get-default")
gdm_active=$(ssh "$HOST" "systemctl is-active gdm.service 2>/dev/null || true")

if [ "$current_target" = "graphical.target" ] && [ "$gdm_active" = "active" ]; then
    echo "Already in desktop mode (graphical.target, GDM running)."
    exit 0
fi

# Set default target + start all desktop services in one remote command (MQTT)
echo "[1/2] Starting desktop services via mesh..."
$MESH '{"command":"sudo systemctl set-default graphical.target && sudo systemctl start accounts-daemon.service power-profiles-daemon.service switcheroo-control.service colord.service gnome-remote-desktop.service cups.service cups-browsed.service gdm.service 2>/dev/null; echo done"}'

# Wait for GDM + X11 to initialize
sleep 5

# Verify (needs stdout → SSH)
echo "[2/2] Verifying desktop state..."
echo ""

gdm_status=$(ssh "$HOST" "systemctl is-active gdm.service 2>/dev/null || true")
echo "  GDM: $gdm_status"

session_type=$(ssh "$HOST" "loginctl show-session \$(loginctl list-sessions --no-legend | awk '/seat0/{print \$1}' | head -1) -p Type --value 2>/dev/null || echo 'pending login'")
echo "  Session type: $session_type"

echo ""
echo "GPU state:"
ssh "$HOST" "nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader"

echo ""
echo "=== Desktop mode active ==="
