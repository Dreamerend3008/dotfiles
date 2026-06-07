# 🏠 Harry's Dotfiles

## 📂 Structure

```
~/dotfiles/
├── flake.nix              # Multi-system configurations
├── home.nix               # User configurations (all systems)
├── README.md
├── cheatSheet.md          # Keybindings & commands reference
└── config/
    ├── hypr/              # Hyprland configuration (modular)
    │   ├── hyprland.conf      # Main entry — sources all modules
    │   ├── monitors.conf      # Monitor layout & resolution
    │   ├── programs.conf      # Default applications ($terminal, $browser, etc.)
    │   ├── input.conf         # Keyboard, mouse, touchpad settings
    │   ├── gestures.conf      # Touchpad gestures (workspace swipe)
    │   ├── cursor.conf        # Cursor theme & behavior
    │   ├── autostart.conf     # Startup applications & daemons
    │   ├── environment.conf   # Environment variables (XDG, toolkit, NVIDIA)
    │   ├── theme.conf         # Appearance (gaps, borders, blur, animations, groups)
    │   ├── windowrules.conf   # Per-app rules (float, opacity, workspace)
    │   ├── keybindings.conf   # All keybindings & resize submap
    │   ├── debug.conf         # Debug & performance toggles
    │   ├── hypridle.conf      # Idle → lock → DPMS → suspend chain
    │   ├── hyprlock.conf      # Lock screen appearance
    │   ├── hyprpaper.conf     # Wallpaper configuration
    │   └── scripts/           # Helper scripts
    │       ├── screenshot.sh      # Area/window/full/monitor screenshots
    │       ├── volume.sh          # Volume control with OSD
    │       ├── brightness.sh      # Brightness control with OSD
    │       ├── wallpaper.sh       # Random wallpaper switcher
    │       └── gamemode.sh        # Toggle gaming mode
    ├── waybar/            # Status bar
    ├── rofi/              # App launcher
    ├── dunst/             # Notifications
    ├── wlogout/           # Power menu (lock, logout, reboot, shutdown)
    ├── nvim/              # Neovim configuration
    ├── kitty/             # Kitty terminal
    ├── ghostty/           # Ghostty terminal
    ├── fastfetch/         # System info
    ├── clangd/            # C++ LSP
    └── starship.toml      # Prompt theme
```

## 🎯 Philosophy

- **Nix = dotfile manager**, not a package manager
- **CachyOS packages** for all Hyprland-related tools (waybar, rofi, dunst, etc.)
- **Modular configs** — each file is self-contained and can be edited independently
- **Catppuccin Mocha** theme across all components

## 📦 CachyOS Packages Required

```bash
# Core Hyprland
sudo pacman -S hyprland hyprlock hypridle hyprpaper xdg-desktop-portal-hyprland

# Bar, Launcher, Notifications
sudo pacman -S waybar rofi-wayland dunst

# Screenshot & Clipboard
sudo pacman -S grim slurp wl-clipboard cliphist

# Power Menu & Utilities
sudo pacman -S wlogout brightnessctl playerctl network-manager-applet

# Optional
yay -S hyprpicker bibata-cursor-theme
```

## 🚀 Installation

### 1. Install Nix

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
# For WSL use: sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

### 2. Enable Flakes

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```
*Restart your terminal after this step.*

### 3. Clone dotfiles

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles ~/dotfiles
cd ~/dotfiles
```

### 4. Configure

- In `flake.nix`: Change `"harry"` to your username.
- In `home.nix`: Update `home.username` and `home.homeDirectory`.

### 5. Apply config

```bash
# First time
nix run . -- switch --flake . -b backup

# Set Zsh as default shell
echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/zsh"
exec zsh
```

## 🧠 Neovim Dependencies

Tools used by `config/nvim` (LSP, formatters, etc.) should be installed via your system package manager (pacman, apt, etc.).
Minimum for C++:
- `g++` 
- `clangd`

## 📖 Daily Use

- `update`: Automatically detects and applies changes (Home Manager or NixOS).
- `ez`: Opens `home.nix` in Neovim.
- `update-home`: Updates only Home Manager.

## 🔄 Syncing

```bash
cd ~/dotfiles
git add .
git commit -m "Update"
git push
# On other machine: git pull && update
```

## 🆘 Troubleshooting

- **zsh: command not found: home-manager**: `source ~/.nix-profile/etc/profile.d/nix.sh`
- **Permission denied**: Use `sudo` if applying to a NixOS system.
- **Icons missing**: Install a Nerd Font.
- **~/.zshrc conflict**: `mv ~/.zshrc ~/.zshrc.backup`
- **Hyprland not loading configs**: Check `hyprctl systeminfo` and logs at `/tmp/hypr/*/hyprland.log`
- **Screen sharing not working**: Ensure `xdg-desktop-portal-hyprland` is installed
- **NVIDIA issues**: Uncomment NVIDIA section in `environment.conf` and set `cursor:no_hardware_cursors = true` in `cursor.conf`
