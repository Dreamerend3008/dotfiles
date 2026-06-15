---
name: home-manager-dotfiles
description: Edit and maintain the ~/dotfiles Home Manager setup safely. Use when changing home.nix, files under config/, or Pi config linked from this repo.
---

# Home Manager Dotfiles

Use this skill when working on `/home/harry/dotfiles`.

## Repo rules

- Read `/home/harry/dotfiles/.AGENTS.md` before making changes.
- Treat `home.nix` as the source of truth. `flake.nix` only exposes the Home Manager config.
- This repo uses Nix mainly as a dotfile manager.
- Keep Hyprland desktop tools such as `waybar`, `rofi`, `dunst`, `hypr*`, `grim`, `slurp`, and similar packages as system/CachyOS packages unless explicitly asked to move them into Nix.
- Never commit secrets. Secrets belong in `~/.secrets`.
- Pi auth is generated into `~/.pi/agent/auth.json` during activation.

## Required workflow

1. Inspect the relevant config file(s) under `config/` and the matching section in `home.nix`.
2. If adding, moving, or deleting anything under `config/`, update the matching `xdg.configFile` or `home.file` entry in `home.nix`.
3. Keep `config/pi/settings.json` authoritative. It is intentionally linked out-of-store so edits there persist exactly as written.
4. Keep changes minimal and consistent with the repo structure.
5. After edits, validate with:

```bash
home-manager switch --flake ~/dotfiles
```

Use the `update` or `update-home` aliases only if that fits the task.

## Pi-specific notes

- Pi resources live in `config/pi/` and are linked into `~/.pi/agent/` from `home.nix`.
- When adding Pi resources such as extensions, themes, prompts, or skills, ensure `home.nix` links them correctly.
- Prefer recursive directory links for grouped Pi resources when appropriate.

## Safe editing checklist

- Check whether the target file is already linked from `home.nix`.
- If a new file is added under `config/`, wire it into Home Manager.
- Avoid changing unrelated packages or desktop tooling.
- Preserve existing formatting and comments unless there is a reason to change them.

## Done criteria

- Requested config changes are implemented.
- `home.nix` mappings stay in sync with the repo.
- Validation command is run or clearly recommended if not executed.
