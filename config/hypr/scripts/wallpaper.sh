#!/usr/bin/env bash
# ============================================================================
# wallpaper.sh — Wallpaper setter for Hyprland
# Supports hyprpaper (primary) and swww (fallback)
# Usage: wallpaper.sh [path_to_wallpaper]
#   No args  → random wallpaper from ~/Pictures/Wallpapers/
#   With arg → use the specified wallpaper file
# ============================================================================

set -euo pipefail

# --- Configuration ----------------------------------------------------------
WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"

# --- Determine wallpaper path -----------------------------------------------
if [[ $# -ge 1 && -f "$1" ]]; then
    # Use the specified wallpaper
    WALLPAPER="$(realpath "$1")"
else
    # Pick a random wallpaper from the wallpaper directory
    if [[ ! -d "${WALLPAPER_DIR}" ]]; then
        notify-send -u critical "Wallpaper" "Directory not found: ${WALLPAPER_DIR}"
        exit 1
    fi

    # Find image files (common formats)
    mapfile -t WALLPAPERS < <(find "${WALLPAPER_DIR}" -maxdepth 1 \
        -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \
        -o -iname '*.webp' -o -iname '*.bmp' \) 2>/dev/null)

    if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
        notify-send -u critical "Wallpaper" "No images found in ${WALLPAPER_DIR}"
        exit 1
    fi

    # Select a random image
    WALLPAPER="${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"
fi

WALLPAPER_NAME=$(basename "${WALLPAPER}")

# --- Apply wallpaper --------------------------------------------------------
if pgrep -x hyprpaper > /dev/null 2>&1; then
    # --- hyprpaper (primary) ------------------------------------------------
    # Unload all current wallpapers, preload the new one, then set it
    hyprctl hyprpaper unload all
    hyprctl hyprpaper preload "${WALLPAPER}"
    # The leading comma means "apply to all monitors"
    hyprctl hyprpaper wallpaper ",${WALLPAPER}"
elif command -v swww > /dev/null 2>&1; then
    # --- swww (fallback) ----------------------------------------------------
    # Start swww daemon if not already running
    if ! pgrep -x swww-daemon > /dev/null 2>&1; then
        swww-daemon &
        sleep 1
    fi

    swww img "${WALLPAPER}" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-duration 2
else
    notify-send -u critical "Wallpaper" "Neither hyprpaper nor swww found"
    exit 1
fi

# --- Send notification -------------------------------------------------------
notify-send -i "${WALLPAPER}" \
    "Wallpaper Changed" \
    "${WALLPAPER_NAME}" \
    -a "Wallpaper" \
    -t 3000
