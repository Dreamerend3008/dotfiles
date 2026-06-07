#!/usr/bin/env bash
# ============================================================================
# screenshot.sh — Hyprland screenshot helper
# Uses grim + slurp for capture, wl-copy for clipboard, dunst for notifications
# Usage: screenshot.sh [area|window|full|monitor]
# ============================================================================

set -euo pipefail

# --- Configuration ----------------------------------------------------------
SCREENSHOT_DIR="${HOME}/Pictures/Screenshots"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
FILENAME="screenshot_${TIMESTAMP}.png"
FILEPATH="${SCREENSHOT_DIR}/${FILENAME}"

# --- Ensure screenshot directory exists -------------------------------------
mkdir -p "${SCREENSHOT_DIR}"

# --- Capture based on mode --------------------------------------------------
case "${1:-area}" in
    area)
        # Interactive area selection via slurp
        grim -g "$(slurp)" "${FILEPATH}"
        ;;
    window)
        # Capture the currently focused window using its geometry
        # Query Hyprland for active window position and size
        GEOMETRY=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')

        if [[ -z "${GEOMETRY}" || "${GEOMETRY}" == "null" ]]; then
            notify-send -u critical "Screenshot" "No active window found"
            exit 1
        fi

        grim -g "${GEOMETRY}" "${FILEPATH}"
        ;;
    full)
        # Capture all monitors (full desktop)
        grim "${FILEPATH}"
        ;;
    monitor)
        # Capture only the currently focused monitor
        MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

        if [[ -z "${MONITOR}" ]]; then
            notify-send -u critical "Screenshot" "No focused monitor found"
            exit 1
        fi

        grim -o "${MONITOR}" "${FILEPATH}"
        ;;
    *)
        echo "Usage: $(basename "$0") [area|window|full|monitor]"
        exit 1
        ;;
esac

# --- Copy to clipboard ------------------------------------------------------
wl-copy < "${FILEPATH}"

# --- Send notification -------------------------------------------------------
notify-send -i "${FILEPATH}" \
    "Screenshot Captured" \
    "${FILENAME}\nSaved to ${SCREENSHOT_DIR}" \
    -a "Screenshot" \
    -t 3000
