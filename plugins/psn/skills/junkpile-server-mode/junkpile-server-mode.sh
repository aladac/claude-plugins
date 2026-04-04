#!/usr/bin/env bash
#
# junkpile-server-mode.sh
#
# Switches junkpile from graphical desktop to server mode by stopping
# GDM, GNOME Shell, X11, and related desktop services. Frees GPU memory
# for compute workloads (Ollama, ComfyUI, etc.).
#
# Runs FROM fuji via SSH. Requires sudo on junkpile.

set -euo pipefail

HOST="j"

run() {
    ssh "$HOST" "sudo $*"
}

run_user() {
    ssh "$HOST" "$*"
}

echo "=== Junkpile: Switching to Server Mode ==="
echo ""

# Check if already in multi-user (server) mode
current_target=$(ssh "$HOST" "systemctl get-default")
if [ "$current_target" = "multi-user.target" ]; then
    # Also verify GDM is actually stopped
    gdm_active=$(ssh "$HOST" "systemctl is-active gdm.service 2>/dev/null || true")
    if [ "$gdm_active" != "active" ]; then
        echo "Already in server mode (multi-user.target, GDM stopped)."
        echo "Done."
        exit 0
    fi
    echo "Default target is multi-user but GDM is still running. Proceeding with shutdown..."
fi

# Step 1: Set default target to multi-user (persists across reboots)
echo "[1/4] Setting default target to multi-user.target..."
run systemctl set-default multi-user.target

# Step 2: Stop GDM (this kills X11, GNOME Shell, and all user graphical sessions)
echo "[2/4] Stopping GDM (display manager)..."
run systemctl stop gdm.service

# Step 3: Stop desktop-adjacent system services that are only needed for GUI
echo "[3/4] Stopping desktop-adjacent system services..."
for service in \
    gnome-remote-desktop.service \
    colord.service \
    switcheroo-control.service \
    power-profiles-daemon.service \
    accounts-daemon.service \
    cups.service \
    cups-browsed.service \
; do
    status=$(ssh "$HOST" "systemctl is-active $service 2>/dev/null || true")
    if [ "$status" = "active" ]; then
        echo "  Stopping $service..."
        run systemctl stop "$service"
    else
        echo "  $service already stopped."
    fi
done

# Step 4: Verify GPU is freed
echo "[4/4] Verifying GPU state..."
echo ""
ssh "$HOST" "nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader"
echo ""
echo "GPU processes remaining:"
ssh "$HOST" "nvidia-smi pmon -c 1 2>/dev/null | grep -v '^#' || echo '  (none)'"

echo ""
echo "=== Server mode active ==="
echo "Desktop services stopped. GPU memory freed for compute."
echo "To restore desktop: bash ~/Projects/personality-plugin/skills/scripts/junkpile-desktop-mode.sh"
