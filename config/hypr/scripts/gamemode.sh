#!/usr/bin/env bash
# ============================================================================
# gamemode.sh — Toggle gaming mode for Hyprland
# Disables eye-candy (animations, blur, shadows, gaps, rounding) for
# maximum performance. Restores defaults by reloading the config.
# Usage: gamemode.sh
# ============================================================================

set -euo pipefail

# --- Configuration ----------------------------------------------------------
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
TOGGLE_FILE="${RUNTIME_DIR}/hypr_gamemode"
NOTIFY_ID=2595             # Fixed notification ID for replace behavior
ENABLE_BATCH="keyword animations:enabled 0 ; keyword decoration:shadow:enabled 0 ; keyword decoration:blur:enabled 0 ; keyword general:gaps_in 0 ; keyword general:gaps_out 0 ; keyword general:border_size 1 ; keyword decoration:rounding 0"

notify() {
    notify-send -r "${NOTIFY_ID}" \
        -i "input-gaming" \
        -a "Gamemode" \
        -t 2000 \
        "$1" \
        "$2"
}

if [[ "${1:-}" == "--self-test" ]]; then
    [[ "${TOGGLE_FILE}" == */hypr_gamemode ]]
    [[ "${ENABLE_BATCH}" == *"keyword animations:enabled 0"* ]]
    [[ "${ENABLE_BATCH}" == *"keyword decoration:blur:enabled 0"* ]]
    echo "ok"
    exit 0
fi

# --- Toggle state -----------------------------------------------------------
if [[ -f "${TOGGLE_FILE}" ]]; then
    # --- Gamemode is ON → turn it OFF ---------------------------------------
    hyprctl reload
    rm -f "${TOGGLE_FILE}"
    notify "Gamemode OFF" "Animations, blur, and effects restored"
else
    # --- Gamemode is OFF → turn it ON ---------------------------------------
    hyprctl --batch "${ENABLE_BATCH}"
    touch "${TOGGLE_FILE}"
    notify "Gamemode ON" "Animations, blur, and effects disabled"
fi
