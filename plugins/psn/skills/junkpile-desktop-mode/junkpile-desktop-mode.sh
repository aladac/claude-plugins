#!/usr/bin/env bash
#
# junkpile-desktop-mode.sh
#
# Switches junkpile back to graphical desktop mode by starting GDM,
# which brings up X11, GNOME Shell, and the full desktop environment.
#
# Runs FROM fuji via SSH. Requires sudo on junkpile.

set -euo pipefail

HOST="j"

run() {
    ssh "$HOST" "sudo $*"
}

echo "=== Junkpile: Switching to Desktop Mode ==="
echo ""

# Check if already in graphical mode
current_target=$(ssh "$HOST" "systemctl get-default")
gdm_active=$(ssh "$HOST" "systemctl is-active gdm.service 2>/dev/null || true")

if [ "$current_target" = "graphical.target" ] && [ "$gdm_active" = "active" ]; then
    echo "Already in desktop mode (graphical.target, GDM running)."
    echo "Done."
    exit 0
fi

# Step 1: Set default target to graphical (persists across reboots)
echo "[1/4] Setting default target to graphical.target..."
run systemctl set-default graphical.target

# Step 2: Start desktop-adjacent system services
echo "[2/4] Starting desktop-adjacent system services..."
for service in \
    accounts-daemon.service \
    power-profiles-daemon.service \
    switcheroo-control.service \
    colord.service \
    gnome-remote-desktop.service \
    cups.service \
    cups-browsed.service \
; do
    status=$(ssh "$HOST" "systemctl is-active $service 2>/dev/null || true")
    if [ "$status" = "active" ]; then
        echo "  $service already running."
    else
        echo "  Starting $service..."
        run systemctl start "$service"
    fi
done

# Step 3: Start GDM (brings up X11 + GNOME Shell + login screen)
echo "[3/4] Starting GDM (display manager)..."
if [ "$gdm_active" = "active" ]; then
    echo "  GDM already running."
else
    run systemctl start gdm.service
fi

# Step 4: Verify
echo "[4/4] Verifying desktop state..."
echo ""

# Wait a moment for X11 to initialize
sleep 3

gdm_status=$(ssh "$HOST" "systemctl is-active gdm.service 2>/dev/null || true")
echo "  GDM: $gdm_status"

session_type=$(ssh "$HOST" "loginctl show-session \$(loginctl list-sessions --no-legend | awk '/seat0/{print \$1}' | head -1) -p Type --value 2>/dev/null || echo 'pending login'")
echo "  Session type: $session_type"

echo ""
echo "GPU state:"
ssh "$HOST" "nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader"

echo ""
echo "=== Desktop mode active ==="
echo "GDM and GNOME desktop services are running."
echo "Log in at the console or via GNOME Remote Desktop."
