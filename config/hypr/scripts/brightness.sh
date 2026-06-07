#!/usr/bin/env bash
# ============================================================================
# brightness.sh — Brightness control helper for Hyprland
# Uses brightnessctl for backlight control, notify-send for notifications
# Usage: brightness.sh [up|down]
# ============================================================================

set -euo pipefail

# --- Configuration ----------------------------------------------------------
STEP=5                     # Brightness change step in percent
NOTIFY_ID=2594             # Fixed notification ID for replace behavior

# --- Helper: get current brightness percentage ------------------------------
get_brightness() {
    brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}'
}

# --- Helper: choose icon based on brightness level --------------------------
get_icon() {
    local level="$1"

    if [[ "${level}" -lt 25 ]]; then
        echo "display-brightness-low"      # or "brightness-low-symbolic"
    elif [[ "${level}" -lt 50 ]]; then
        echo "display-brightness-medium"
    elif [[ "${level}" -lt 75 ]]; then
        echo "display-brightness-high"
    else
        echo "display-brightness-full"     # or "display-brightness-symbolic"
    fi
}

# --- Perform action ---------------------------------------------------------
case "${1:-}" in
    up)
        # Increase brightness by STEP%
        brightnessctl set "${STEP}%+"
        ;;
    down)
        # Decrease brightness by STEP%, min 1% to prevent black screen
        brightnessctl set "${STEP}%-" -n 1
        ;;
    *)
        echo "Usage: $(basename "$0") [up|down]"
        exit 1
        ;;
esac

# --- Build and send notification --------------------------------------------
BRIGHTNESS=$(get_brightness)
ICON=$(get_icon "${BRIGHTNESS}")

# Send notification with replace-id so it updates in place
notify-send -r "${NOTIFY_ID}" \
    -i "${ICON}" \
    -h "int:value:${BRIGHTNESS}" \
    -a "Brightness" \
    -t 1500 \
    "Brightness" "${BRIGHTNESS}%"
