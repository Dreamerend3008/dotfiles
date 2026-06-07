#!/usr/bin/env bash
# ============================================================================
# gamemode.sh — Toggle gaming mode for Hyprland
# Disables eye-candy (animations, blur, shadows, gaps, rounding) for
# maximum performance. Restores defaults by reloading the config.
# Usage: gamemode.sh
# ============================================================================

set -euo pipefail

# --- Configuration ----------------------------------------------------------
TOGGLE_FILE="/tmp/hypr_gamemode"
NOTIFY_ID=2595             # Fixed notification ID for replace behavior

# --- Toggle state -----------------------------------------------------------
if [[ -f "${TOGGLE_FILE}" ]]; then
    # --- Gamemode is ON → turn it OFF ---------------------------------------
    rm -f "${TOGGLE_FILE}"

    # Reload Hyprland config to restore all defaults
    hyprctl reload

    notify-send -r "${NOTIFY_ID}" \
        -i "input-gaming" \
        -a "Gamemode" \
        -t 2000 \
        "Gamemode OFF" \
        "Animations, blur, and effects restored"
else
    # --- Gamemode is OFF → turn it ON ---------------------------------------
    touch "${TOGGLE_FILE}"

    # Disable all eye-candy in one batch call for atomicity
    hyprctl --batch "\
        keyword animations:enabled 0; \
        keyword decoration:shadow:enabled 0; \
        keyword decoration:blur:enabled 0; \
        keyword general:gaps_in 0; \
        keyword general:gaps_out 0; \
        keyword general:border_size 1; \
        keyword decoration:rounding 0"

    notify-send -r "${NOTIFY_ID}" \
        -i "input-gaming" \
        -a "Gamemode" \
        -t 2000 \
        "Gamemode ON" \
        "Animations, blur, and effects disabled"
fi
