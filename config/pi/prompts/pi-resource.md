---
description: Add or modify Pi resources in ~/dotfiles/config/pi and keep Home Manager links in sync
argument-hint: "[resource/task]"
---
Work on Pi resources inside `~/dotfiles/config/pi`.

Focus on one of these areas as needed:
- extensions
- themes
- prompt templates
- skills
- models
- keybindings
- settings

Requirements:
- Treat `config/pi/settings.json` as authoritative.
- If you add, move, or delete files under `config/pi/`, update the matching `home.file` entry in `~/dotfiles/home.nix`.
- Keep changes minimal and consistent with the current Pi setup.
- Never add secrets to the repo.
- Validate with `home-manager switch --flake ~/dotfiles` after config changes.

Use Pi docs when needed for exact format or capabilities.

Task: ${1:-Inspect the current Pi configuration, implement the requested resource change, wire it through Home Manager if needed, and validate it.}
