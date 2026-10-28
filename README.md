# 🏠 Harry's Dotfiles

Home Manager-based dotfiles for my Arch / CachyOS desktop.

This repo uses **Nix mainly as a dotfile manager**. It does not try to fully own the whole system. A lot of the desktop stack is expected to come from your distro packages, while Home Manager links the config files and installs a smaller set of CLI tools.

## Who this is for

This setup fits best if you want:

- a **Hyprland** desktop on Arch / CachyOS
- **Home Manager standalone** for dotfiles
- modular config files you can edit independently
- my Pi terminal agent setup, themes, prompts, and extensions

If you are on a very different distro or desktop environment, use this as a base, not as a drop-in exact clone.

## What this repo manages

### Shell and terminal
- Zsh
- Starship
- Zoxide, FZF, LSD, Bat, Ripgrep, FD, Tree
- Fastfetch
- Kitty and Ghostty config

### Development
- Git config and aliases
- Neovim config
- Node.js, CMake, GNU Make, pkg-config
- Clangd config
- small competitive-programming helpers

### Desktop / Hyprland
- modular Hyprland config in `config/hypr/`
- Waybar
- Rofi
- Dunst
- Wlogout
- Hypridle / Hyprlock / Hyprpaper config
- helper scripts for screenshots, volume, brightness, wallpaper, and eyecare

### Pi terminal agent
- models, settings, keybindings
- extensions, prompts, skills, themes, agents
- activation-time auth generation from local env vars in `~/.secrets`

## Repository layout

```text
~/dotfiles/
├── flake.nix
├── home.nix
├── README.md
├── cheatSheet.md
├── utils/
└── config/
    ├── clangd/
    ├── dunst/
    ├── fastfetch/
    ├── ghostty/
    ├── hypr/
    │   ├── hyprland.conf
    │   ├── monitors.conf
    │   ├── programs.conf
    │   ├── input.conf
    │   ├── gestures.conf
    │   ├── cursor.conf
    │   ├── environment.conf
    │   ├── theme.conf
    │   ├── windowrules.conf
    │   ├── keybindings.conf
    │   ├── autostart.conf
    │   ├── debug.conf
    │   ├── hypridle.conf
    │   ├── hyprlock.conf
    │   ├── hyprpaper.conf
    │   ├── scripts/
    │   └── shaders/
    ├── kitty/
    ├── nvim/
    ├── pi/
    ├── rofi/
    ├── waybar/
    └── wlogout/
```

## Source of truth

- `home.nix` is the main Home Manager config
- `flake.nix` only exposes the Home Manager entrypoint
- files under `config/` are linked into place by Home Manager
- `config/pi/settings.json` is intentionally linked out-of-store so edits made from Pi persist back into this repo

## Prerequisites

## 1. Install Nix

Single-user / daemon install:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

WSL / no-daemon variant:

```bash
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

## 2. Enable flakes

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

Restart your shell after this.

## 3. Install Home Manager

This repo is meant to be applied with **Home Manager standalone**.
Install Home Manager for your machine first, then use `home-manager switch --flake ...` from this repo.

```bash
nix run home-manager/master -- switch --flake .#harry
```

## 4. Install required system packages

These are intentionally **not** managed by Nix here and should come from your distro.
For Arch / CachyOS, install at least:

```bash
sudo pacman -S \
  hyprland hyprlock hypridle hyprpaper xdg-desktop-portal xdg-desktop-portal-hyprland \
  waybar rofi-wayland dunst wlogout \
  ghostty firefox \
  grim slurp wl-clipboard cliphist \
  brightnessctl playerctl network-manager-applet \
  papirus-icon-theme
```

Useful extras:

```bash
yay -S bibata-cursor-theme
```

Optional extras referenced in comments or optional bindings:

```bash
sudo pacman -S blueman udiskie
# optional AUR / repo depending on your system
# hyprpicker
# swayosd
```

If you do not install some of these, parts of the config will still work, but launcher, notifications, lock screen, screenshots, media keys, or tray items may be missing.

## Install and personalize

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles ~/dotfiles
cd ~/dotfiles
```

### 2. Update the personal values

Before applying, edit these values to match your machine:

#### In `home.nix`
- `home.username`
- `home.homeDirectory`
- Git identity under `programs.git.settings`

#### In `flake.nix`
- `homeConfigurations."harry"` if you want the flake output name to match your user

You can either:
- rename the flake entry to your own username, or
- keep it as-is and apply with `home-manager switch --flake ~/dotfiles#harry`

#### Optional personal touches to change
- `config/hypr/programs.conf` — terminal, browser, file manager, launcher
- `config/hypr/monitors.conf` — monitor layout / scale / refresh
- `config/hypr/hyprpaper.conf` — wallpaper path
- `config/hypr/hyprlock.conf` — greeting text
- `README.md` title if you fork it publicly

### 3. Set up secrets for Pi

If you want the Pi terminal agent config to work, create `~/.secrets`:

```bash
cat > ~/.secrets <<'EOF'
# API Keys / endpoints — DO NOT COMMIT
export AZURE_OPENAI_API_KEY="your-azure-api-key"
export AZURE_FOUNDRY_BASE_URL="https://your-resource.services.ai.azure.com/api/projects/your-project/openai/v1"
# optional
# export NVIDIA_NIM_API_KEY="your-nvidia-api-key"
EOF
chmod 600 ~/.secrets
```

What these do:
- `AZURE_OPENAI_API_KEY` — API key for the Azure Foundry provider
- `AZURE_FOUNDRY_BASE_URL` — your Azure Foundry OpenAI-compatible base URL
- `NVIDIA_NIM_API_KEY` — optional extra provider auth

During activation, Home Manager generates `~/.pi/agent/auth.json` from these local env vars.

If you do **not** want Pi right now, you can still use the rest of the dotfiles. Just expect the Pi config to be present but not authenticated until you add those vars.

### 4. Apply the config

If you renamed the flake output to your own username:

```bash
home-manager switch --flake ~/dotfiles
```

If you kept the output name as `harry`:

```bash
home-manager switch --flake ~/dotfiles#harry
```

On systems where `/etc/nixos/configuration.nix` exists, the `update` alias in `home.nix` will choose between `home-manager switch` and `nixos-rebuild switch` automatically.

### 5. Log out and back in

For the full desktop experience, log out and log back in to your Hyprland session after the first apply.

## Daily use

### Useful shell aliases

Defined in `home.nix`:

- `update` — apply dotfiles on Home Manager
- `update-home` — apply only Home Manager
- `update-system` — run `nixos-rebuild switch --flake ~/dotfiles`
- `ez` — open `home.nix`
- `hy` — jump to `config/hypr/`
- `lg` — open Lazygit
- `gs` / `gp` / `gl` — Git shortcuts

### Hyprland structure

`config/hypr/hyprland.conf` is the top-level dispatcher. It sources the modular files:

- `monitors.conf` — monitor layout
- `programs.conf` — terminal, browser, launcher, file manager
- `input.conf` — keyboard / mouse / touchpad
- `gestures.conf` — touchpad gestures
- `cursor.conf` — cursor settings
- `theme.conf` — gaps, borders, colors, rounding, blur
- `environment.conf` — environment variables
- `windowrules.conf` — per-app rules
- `keybindings.conf` — most shortcuts
- `autostart.conf` — bars, notifications, portal, tray, clipboard, wallpaper
- `debug.conf` — performance / debug tweaks

Other important Hypr files:
- `hypridle.conf` — idle behavior
- `hyprlock.conf` — lock screen UI
- `hyprpaper.conf` — wallpaper manager
- `scripts/` — helper scripts used by binds and autostart
- `shaders/` — eyecare color filters

For keybinds, see `cheatSheet.md`.

### Neovim

Neovim starts from `config/nvim/init.lua` and loads modules from `config/nvim/lua/`.

High-level pieces:
- `options.lua` — editor options
- `keymaps.lua` — keymaps
- `plugins.lua` — plugin list and setup
- `lsp.lua` — LSP config
- `completion.lua` — autocomplete
- `cp.lua` — competitive-programming helpers

### Emacs

Install emacs 

sudo pacman -S emacs

Install Doom emacs

git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs

~/.config/emacs/bin/doom install


### Pi terminal agent

Pi files live under `config/pi/` and are linked into `~/.pi/agent/`.

Important pieces:
- `models.json` — provider/model definitions
- `settings.json` — active UI + model settings
- `keybindings.json` — Pi keybindings
- `extensions/` — local Pi extensions
- `themes/` — custom themes
- `prompts/`, `skills/`, `agents/` — custom Pi resources

## Updating the repo safely

When you add or move files under `config/`, also update the matching `xdg.configFile` or `home.file` entry in `home.nix`.

After changes:

```bash
home-manager switch --flake ~/dotfiles#harry
```

Use your own flake name if you renamed it.

## Troubleshooting

### `home-manager switch` works but desktop pieces are missing
Usually that means a required system package is not installed. Check the package list above first.

### Hyprland reload warning during activation
If Home Manager says `HYPRLAND_INSTANCE_SIGNATURE not set`, that usually just means the activation ran outside a live Hyprland session. It is harmless.

### Pi has no auth
Make sure:
- `~/.secrets` exists
- the env vars are exported exactly
- you ran `home-manager switch` again after creating the file

### Rofi / Waybar / Dunst / screenshots do nothing
Install the matching system packages from the prerequisites section and verify the binaries exist in `PATH`.

## Notes

- Secrets stay local in `~/.secrets` and should never be committed
- Preserve executable bits for `config/hypr/scripts/*.sh`
- Keep `README.md` in sync with `home.nix` when the repo structure changes
- This repo is optimized for my own setup first; fork and trim aggressively if you only want parts of it
