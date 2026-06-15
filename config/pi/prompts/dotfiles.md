---
description: Edit ~/dotfiles safely using the repo rules from .AGENTS.md
argument-hint: "[task]"
---
You are working in `~/dotfiles`.

Follow these repo rules exactly:

- `home.nix` is the main source of truth; `flake.nix` only exposes the Home Manager config.
- This repo uses Nix mainly as a **dotfile manager**. Keep Hyprland desktop apps/tools (`waybar`, `rofi`, `dunst`, `hypr*`, `grim`, `slurp`, etc.) as system/CachyOS packages unless asked otherwise.
- When adding, moving, or deleting files under `config/`, also update the matching `xdg.configFile` / `home.file` entry in `home.nix`.
- Hyprland is modular: edit the relevant file in `config/hypr/`, and keep `config/hypr/hyprland.conf` as the top-level dispatcher.
- `config/pi/settings.json` is authoritative and linked out-of-store on purpose; edits there should persist exactly as written.
- Never commit secrets. Keys belong in `~/.secrets`; Pi auth is generated into `~/.pi/agent/auth.json` during activation.
- Preserve executable bits for `config/hypr/scripts/*.sh`.
- After config changes, validate with `home-manager switch --flake ~/dotfiles` (or the `update` / `update-home` aliases).

Workflow:
1. Read the relevant file(s) first.
2. Make the smallest targeted change.
3. If the task adds or removes files under `config/`, update `home.nix`.
4. Validate the result.
5. Summarize exactly what changed and mention any follow-up.

Task: ${1:-Inspect the current dotfiles setup, ask clarifying questions only if needed, and make the requested edit safely.}
