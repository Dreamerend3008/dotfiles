#!/usr/bin/env bash
# ============================================================================
# wallpaper.sh — Wallpaper setter for Hyprland
# Supports hyprpaper (primary) and swww (fallback)
# Usage: wallpaper.sh [path_to_wallpaper]
#   No args  → sequential wallpaper from ~/dotfiles/utils/wallpapers/
#   With arg → use the specified wallpaper file
# ============================================================================

set -euo pipefail

# --- Configuration ----------------------------------------------------------
WALLPAPER_DIR="${HOME}/dotfiles/utils/wallpapers"

# --- Determine wallpaper path -----------------------------------------------
if [[ $# -ge 1 && -f "$1" ]]; then
    # Use the specified wallpaper
    WALLPAPER="$(realpath "$1")"
else
    # Pick the next wallpaper from the wallpaper directory in alphabetical order
    if [[ ! -d "${WALLPAPER_DIR}" ]]; then
        notify-send -u critical "Wallpaper" "Directory not found: ${WALLPAPER_DIR}"
        exit 1
    fi

    # Find image files (common formats) and sort them for sequential rotation
    mapfile -t WALLPAPERS < <(find "${WALLPAPER_DIR}" -maxdepth 1 \
        -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \
        -o -iname '*.webp' -o -iname '*.bmp' \) 2>/dev/null | sort)

    if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
        notify-send -u critical "Wallpaper" "No images found in ${WALLPAPER_DIR}"
        exit 1
    fi

    STATE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/hyprland"
    STATE_FILE="${STATE_DIR}/wallpaper.index"
    mkdir -p "${STATE_DIR}"

    LAST_INDEX=-1
    if [[ -f "${STATE_FILE}" ]]; then
        read -r LAST_INDEX < "${STATE_FILE}" || LAST_INDEX=-1
    fi

    NEXT_INDEX=$(( (LAST_INDEX + 1) % ${#WALLPAPERS[@]} ))
    printf '%s\n' "${NEXT_INDEX}" > "${STATE_FILE}"
    WALLPAPER="${WALLPAPERS[${NEXT_INDEX}]}"
fi

WALLPAPER_NAME=$(basename "${WALLPAPER}")

# --- Apply wallpaper --------------------------------------------------------
if pgrep -x hyprpaper > /dev/null 2>&1; then
    # --- hyprpaper (primary) ------------------------------------------------
    # Hyprpaper v0.8 uses a single IPC command with monitor, path and fit mode.
    # The empty monitor target acts as the fallback wallpaper.
    hyprctl hyprpaper wallpaper ", ${WALLPAPER}, cover"
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
