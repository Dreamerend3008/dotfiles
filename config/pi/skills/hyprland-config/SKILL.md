---
name: hyprland-config
description: Modify the modular Hyprland setup in ~/dotfiles safely. Use when changing keybindings, monitors, theme, autostart, window rules, scripts, or other files under config/hypr/.
---

# Hyprland Config

Use this skill for changes under `/home/harry/dotfiles/config/hypr`.

## Repo rules

- Read `/home/harry/dotfiles/.AGENTS.md` first.
- Hyprland is modular. Edit the specific file that owns the behavior.
- Keep `config/hypr/hyprland.conf` as the top-level dispatcher instead of dumping all config there.
- Preserve executable bits for `config/hypr/scripts/*.sh`.
- Keep Hyprland desktop applications and utilities as system/CachyOS packages unless explicitly asked otherwise.

## Module map

Choose the smallest relevant file:

- `monitors.conf` — monitor layout, refresh rate, scale
- `programs.conf` — default apps and launch commands
- `input.conf` — keyboard, mouse, touchpad
- `gestures.conf` — touchpad/workspace gestures
- `cursor.conf` — cursor settings
- `autostart.conf` — startup daemons and applications
- `environment.conf` — environment variables and toolkit behavior
- `theme.conf` — gaps, borders, blur, animations
- `windowrules.conf` — float, workspace, opacity, app-specific rules
- `keybindings.conf` — keybinds and submaps
- `debug.conf` — debugging and performance toggles
- `hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf` — related Hypr ecosystem tools
- `scripts/*.sh` — helper scripts invoked by binds or startup

## Required workflow

1. Inspect the specific Hyprland module before editing.
2. Make the change in the smallest relevant file.
3. If adding a new script, place it under `config/hypr/scripts/`, keep it executable, and wire it into the relevant config file.
4. If adding, moving, or deleting files under `config/`, update the matching `xdg.configFile` or `home.file` entry in `home.nix`.
5. Validate by applying the dotfiles:

```bash
home-manager switch --flake ~/dotfiles
```

The Home Manager config already reloads Hyprland via `hyprctl reload` when the linked config changes.

## Editing guidance

- Prefer small targeted edits over broad rewrites.
- Do not move package installation into Nix unless requested.
- Keep naming and formatting consistent with the existing Hyprland files.
- If a change affects scripts, keybindings, or startup, mention any follow-up testing to perform.

## Done criteria

- The requested behavior is implemented in the correct Hyprland module.
- Any new files are linked correctly through `home.nix`.
- Script executability is preserved.
- Validation is run or clearly recommended.
