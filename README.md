# 🏠 Harry's Dotfiles

> Declarative development environment using **Nix Home Manager**.
> One command to set up everything on any Linux machine or WSL!

## ✨ What's Included

| Tool | Description |
|------|-------------|
| **zsh** | Shell with oh-my-zsh, autosuggestions, syntax highlighting |
| **starship** | Beautiful, fast prompt |
| **neovim** | Configured with LSP, completion, treesitter |
| **lsd** | Modern `ls` with icons |
| **zoxide** | Smarter `cd` command |
| **lazygit** | Terminal UI for git |
| **fastfetch** | System info display |
| **fzf** | Fuzzy finder |
| + more | ripgrep, fd, bat, htop, btop... |

## 🚀 Quick Install (New Machine)

### One-liner (after setting up the repo):
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/install.sh | bash
```

### Or step by step:
```bash
# 1. Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon
# For WSL, use: sh <(curl -L https://nixos.org/nix/install) --no-daemon

# 2. Enable Flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# 3. Clone and apply
git clone https://github.com/YOUR_USERNAME/dotfiles ~/dotfiles
cd ~/dotfiles
nix run . -- switch --flake .

# 4. Set Zsh as default shell
echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/zsh"

# 5. Restart terminal or run: exec zsh
```

## 📝 Daily Usage

### After editing `home.nix`:
```bash
update   # Alias for: home-manager switch --flake ~/dotfiles
```

### Quick edit config:
```bash
ez       # Opens home.nix in neovim
```

### Search for new packages:
```bash
nix search nixpkgs <package-name>
# Or visit: https://search.nixos.org/packages
```

## 📁 Structure

```
~/dotfiles/
├── flake.nix           # Entry point - defines inputs (nixpkgs, home-manager)
├── home.nix            # Main config - packages, shell, programs
├── install.sh          # One-command installer
├── README.md           # This file
└── config/
    ├── nvim/           # Neovim configuration
    │   ├── init.lua
    │   └── lua/
    │       ├── options.lua
    │       ├── keymaps.lua
    │       ├── plugins.lua
    │       ├── lsp.lua
    │       ├── completion.lua
    │       └── cp.lua
    ├── starship.toml   # Prompt configuration
    └── fastfetch/      # System info display
        ├── config.jsonc
        ├── config-minimal.jsonc
        └── logos/
```

## 🔧 Customization

### Add a new package:
Edit `home.nix`, find the `home.packages` section, add your package:
```nix
home.packages = with pkgs; [
  # ... existing packages ...
  your-new-package    # Add this line
];
```
Then run `update`.

### Add a shell alias:
Edit `home.nix`, find `programs.zsh.shellAliases`:
```nix
shellAliases = {
  # ... existing aliases ...
  myalias = "my-command";
};
```

### Change git settings:
Edit `home.nix`, find `programs.git`:
```nix
programs.git = {
  userName = "Your Name";
  userEmail = "your@email.com";
  # ...
};
```

## 🖥️ WSL Notes

For WSL, the install script automatically uses single-user Nix installation.

If using Windows Terminal, make sure you have a Nerd Font installed (like JetBrainsMono Nerd Font) for icons to display correctly.

For the fastfetch logo with images, you may need to use `config-minimal.jsonc` instead (uses ASCII art):
```nix
# In home.nix, change:
fastfetch -c ~/.config/fastfetch/config-minimal.jsonc
```

## 🔄 Sync Changes Between Machines

```bash
# On machine where you made changes:
cd ~/dotfiles
git add .
git commit -m "description of changes"
git push

# On other machine:
cd ~/dotfiles
git pull
update   # Apply the changes
```

## 📚 Learning Resources

- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learn Nix language
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- [Nixpkgs Search](https://search.nixos.org/packages)

## ⚠️ First Time Setup Reminders

1. **Change username** in `flake.nix` and `home.nix`:
   ```nix
   home.username = "your-username";
   home.homeDirectory = "/home/your-username";
   ```

2. **Change git config** in `home.nix`:
   ```nix
   userName = "Your Name";
   userEmail = "your@email.com";
   ```

3. **Change GitHub username** in `install.sh`:
   ```bash
   GITHUB_USER="your-username"
   ```

---

Made with ❤️ and Nix
