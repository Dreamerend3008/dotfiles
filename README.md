# 🏠 Harry's Dotfiles

Home Manager-based dotfiles for my Arch/CachyOS setup.

## At a glance

- `home.nix` is the source of truth for the Home Manager config
- `flake.nix` only exposes the Home Manager entrypoint
- `config/` contains the dotfiles that Home Manager links into place
- `cheatSheet.md` has quick keybindings and common commands
- Pi resources live under `config/pi/` and are linked into `~/.pi/agent/`

## What this repo covers

### Shell and terminal
- Zsh, Starship, Zoxide, FZF, LSD, Bat, Eza, Ripgrep, FD, Tree, Htop, Btop, Yazi
- Kitty and Ghostty configs
- Fastfetch and Clangd config
- Utility aliases and helper functions in `home.nix`

### Development
- Git settings and aliases
- Neovim config
- Node.js, pkg-config, CMake, GNU Make
- Python 3.11 and system libraries for local builds

### Desktop / Hyprland
- Modular Hyprland config under `config/hypr/`
- Waybar, Rofi, Dunst, Wlogout config files
- `hyprland.conf` acts as the top-level dispatcher for the modular Hyprland setup
- System desktop tools are intentionally expected from CachyOS / system packages, not Nix

### Pi terminal agent
- Model, settings, keybinding, and extension config
- Prompt, skill, theme, and project-manager resources
- Out-of-store `settings.json` so Pi changes persist directly back into the repo
- Activation-time Pi auth generation from `~/.secrets`

## Repository layout

```text
~/dotfiles/
├── flake.nix
├── home.nix
├── README.md
├── cheatSheet.md
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
    │   ├── autostart.conf
    │   ├── environment.conf
    │   ├── theme.conf
    │   ├── windowrules.conf
    │   ├── keybindings.conf
    │   ├── debug.conf
    │   ├── hypridle.conf
    │   ├── hyprlock.conf
    │   ├── hyprpaper.conf
    │   └── scripts/
    ├── kitty/
    ├── nvim/
    ├── pi/
    │   ├── extensions/
    │   ├── prompts/
    │   ├── skills/
    │   ├── themes/
    │   ├── project-manager/
    │   ├── keybindings.json
    │   ├── models.json
    │   ├── settings.json
    │   ├── model-cost-extension.ts
    │   ├── usage-extension.ts
    │   └── session-manager-extension.ts
    ├── rofi/
    ├── starship.toml
    ├── waybar/
    └── wlogout/
```

## Philosophy

- Nix is used mainly as a dotfile manager, not a package manager
- Hyprland desktop apps/tools like `waybar`, `rofi`, `dunst`, `hypr*`, `grim`, `slurp`, etc. are expected to come from system/CachyOS packages
- Configs are modular so each file can be edited independently
- Secrets stay local in `~/.secrets` and are never committed
- Keep the README readable by grouping related config instead of listing every file inline

## Required system packages

Install the desktop tools that are intentionally kept outside Nix:

```bash
sudo pacman -S \
  hyprland hyprlock hypridle hyprpaper xdg-desktop-portal-hyprland \
  waybar rofi-wayland dunst \
  grim slurp wl-clipboard cliphist \
  wlogout brightnessctl playerctl network-manager-applet
```

Optional extras:

```bash
yay -S hyprpicker bibata-cursor-theme
```

## Setup

### 1. Install Nix

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

For WSL:

```bash
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

### 2. Enable flakes

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

Restart your terminal after this step.

### 3. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles ~/dotfiles
cd ~/dotfiles
```

### 4. Configure your username

Update `home.nix` (and `flake.nix` if needed) for your username/home directory.

### 5. Set up secrets for Pi

Create `~/.secrets` for API keys. It is gitignored and loaded by the shell and Pi activation:

```bash
cat > ~/.secrets <<'EOF'
# API Keys — DO NOT COMMIT
export AZURE_OPENAI_API_KEY="your-azure-api-key-here"
EOF
chmod 600 ~/.secrets
```

Home Manager generates `~/.pi/agent/auth.json` from that variable during activation.

### 6. Apply the config

```bash
home-manager switch --flake ~/dotfiles
```

If you are on NixOS, the `update` alias in `home.nix` will choose between Home Manager and `nixos-rebuild`.

## Pi terminal agent

Pi is configured through files under `config/pi/` and linked into `~/.pi/agent/` by Home Manager.

- `settings.json` is intentionally linked out-of-store so changes from Pi persist in the repo
- `models.json` defines the available models
- `keybindings.json` and the `*-extension.ts` files provide Pi custom actions
- `project-manager/` adds repo-aware project tooling
- prompt, skill, and theme resources are linked from `config/pi/`

## Daily use

Useful shell aliases from `home.nix`:

- `update` — apply dotfiles on Home Manager or NixOS
- `update-home` — apply only Home Manager
- `update-system` — run `nixos-rebuild switch --flake ~/dotfiles`
- `ez` — open `home.nix`
- `hy` — jump to the Hyprland config directory

## Notes

- `config/hypr/hyprland.conf` is the top-level Hyprland dispatcher
- Preserve executable bits for `config/hypr/scripts/*.sh`
- Keep secrets out of the repo
- Keep this README in sync with `home.nix` when adding or moving config files
- If you add new config files under `config/`, wire them in through `home.nix`
