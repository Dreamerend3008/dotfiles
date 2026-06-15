---
description: Edit the modular Hyprland config in ~/dotfiles safely
argument-hint: "[task]"
---
Modify the Hyprland setup in `~/dotfiles/config/hypr`.

Rules:
- Read `~/dotfiles/.AGENTS.md` first.
- Keep `config/hypr/hyprland.conf` as the dispatcher, not the dumping ground.
- Edit the smallest relevant module (`monitors.conf`, `theme.conf`, `keybindings.conf`, `windowrules.conf`, `autostart.conf`, scripts, etc.).
- Preserve executable bits for `config/hypr/scripts/*.sh`.
- Keep Hyprland-related packages as system/CachyOS packages unless explicitly asked otherwise.
- If files are added, moved, or deleted under `config/`, update `home.nix` too.
- Validate with `home-manager switch --flake ~/dotfiles`.

Task: ${1:-Inspect the relevant Hyprland module and implement the requested change cleanly.}
