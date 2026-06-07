#!/usr/bin/env bash
# ============================================================================
# volume.sh — Volume control helper for Hyprland
# Uses wpctl (WirePlumber) for audio control, notify-send for notifications
# Usage: volume.sh [up|down|mute]
# ============================================================================

set -euo pipefail

# --- Configuration ----------------------------------------------------------
STEP=5                     # Volume change step in percent
LIMIT=1.0                  # Maximum volume limit (1.0 = 100%)
NOTIFY_ID=2593             # Fixed notification ID for replace behavior

# --- Helper: get current volume and mute state ------------------------------
get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'
}

is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "[MUTED]"
}

# --- Helper: choose icon based on volume level ------------------------------
get_icon() {
    local vol="$1"
    local muted="$2"

    if [[ "${muted}" == "yes" ]] || [[ "${vol}" -eq 0 ]]; then
        echo "audio-volume-muted"
    elif [[ "${vol}" -lt 33 ]]; then
        echo "audio-volume-low"
    elif [[ "${vol}" -lt 66 ]]; then
        echo "audio-volume-medium"
    else
        echo "audio-volume-high"
    fi
}

# --- Perform action ---------------------------------------------------------
case "${1:-}" in
    up)
        # Increase volume by STEP%, capped at LIMIT
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${STEP}%+" --limit "${LIMIT}"
        ;;
    down)
        # Decrease volume by STEP%
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${STEP}%-"
        ;;
    mute)
        # Toggle mute state
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *)
        echo "Usage: $(basename "$0") [up|down|mute]"
        exit 1
        ;;
esac

# --- Build and send notification --------------------------------------------
VOLUME=$(get_volume)

if is_muted; then
    MUTED="yes"
else
    MUTED="no"
fi

ICON=$(get_icon "${VOLUME}" "${MUTED}")

if [[ "${MUTED}" == "yes" ]]; then
    TEXT="Muted"
else
    TEXT="${VOLUME}%"
fi

# Send notification with replace-id so it updates in place
notify-send -r "${NOTIFY_ID}" \
    -i "${ICON}" \
    -h "int:value:${VOLUME}" \
    -a "Volume" \
    -t 1500 \
    "Volume" "${TEXT}"
