#!/usr/bin/env bash
# ==========================================================================
# eyecare.sh — Eye comfort / night light toggle helper for Hyprland
# Uses Hyprland's built-in screen_shader and notify-send
# Usage: eyecare.sh [toggle|on|off|warm|warmer|cool|status]
# ==========================================================================

set -euo pipefail

NOTIFY_ID=2594
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SHADER_DIR="${SCRIPT_DIR%/scripts}/shaders"
WARM_SHADER="${SHADER_DIR}/eyecare-warm.frag"
WARMER_SHADER="${SHADER_DIR}/eyecare-warmer.frag"
COOL_SHADER="${SHADER_DIR}/eyecare-cool.frag"
DEFAULT_SHADER="[[EMPTY]]"

lua_escape() {
    python -c 'import sys; s=sys.argv[1]; print(s.replace("\\", "\\\\").replace("\x27", "\\\x27"))' "$1"
}

get_current_shader() {
    hyprctl getoption decoration.screen_shader 2>/dev/null | awk -F': ' '/^str:/ {print $2}'
}

set_shader() {
    local shader="$1"
    hyprctl eval "hl.config({ decoration = { screen_shader = '$(lua_escape "$shader")' } })" >/dev/null
}

current_label() {
    case "$(get_current_shader)" in
        "${WARM_SHADER}") echo "Warm" ;;
        "${WARMER_SHADER}") echo "Warmer" ;;
        "${COOL_SHADER}") echo "Cool" ;;
        "${DEFAULT_SHADER}"|"") echo "Off" ;;
        *) echo "Custom" ;;
    esac
}

current_value() {
    case "$(get_current_shader)" in
        "${WARM_SHADER}") echo "R 1.00 · G 0.93 · B 0.82 · Dim 0.98" ;;
        "${WARMER_SHADER}") echo "R 1.00 · G 0.88 · B 0.72 · Dim 0.95" ;;
        "${COOL_SHADER}") echo "R 1.00 · G 0.97 · B 0.90" ;;
        "${DEFAULT_SHADER}"|"") echo "Disabled" ;;
        *) echo "Shader: $(get_current_shader)" ;;
    esac
}

notify_state() {
    notify-send -r "${NOTIFY_ID}" \
        -i "display-brightness" \
        -a "Eye Comfort" \
        -t 1800 \
        "Eye Comfort: $(current_label)" \
        "$(current_value)"
}

case "${1:-toggle}" in
    toggle)
        case "$(get_current_shader)" in
            "${WARM_SHADER}"|"${WARMER_SHADER}"|"${COOL_SHADER}") set_shader "" ;;
            *) set_shader "${WARM_SHADER}" ;;
        esac
        ;;
    on|warm)
        set_shader "${WARM_SHADER}"
        ;;
    warmer)
        set_shader "${WARMER_SHADER}"
        ;;
    cool)
        set_shader "${COOL_SHADER}"
        ;;
    off)
        set_shader ""
        ;;
    status)
        ;;
    *)
        echo "Usage: $(basename "$0") [toggle|on|off|warm|warmer|cool|status]"
        exit 1
        ;;
esac

notify_state
