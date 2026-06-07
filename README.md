# 🏠 Harry's Dotfiles

## 📂 Structure

```
~/dotfiles/
├── flake.nix              # Multi-system configurations
├── home.nix               # User configurations (all systems)
├── README.md
└── config/
    ├── nvim/
    ├── hypr/              # Hyprland configuration
    ├── starship.toml
    └── fastfetch/
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
