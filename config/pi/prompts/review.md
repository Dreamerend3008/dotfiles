---
description: Review current git changes with emphasis on correctness, config linkage, and regressions
argument-hint: "[scope]"
---
Review the current git changes${1:+ for $1}.

Check for:
- broken logic or incorrect edits
- missing `home.nix` mappings for files added under `config/`
- accidental edits to `config/pi/settings.json`
- secrets or sensitive values that should live in `~/.secrets`
- Hyprland changes made in the wrong module
- missing validation or obvious follow-up testing

Prefer reviewing `git diff --cached` if there are staged changes, otherwise review the working tree diff.

Return:
1. findings ordered by severity
2. risky assumptions
3. quick validation steps
4. if clean, say so clearly
