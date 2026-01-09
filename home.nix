# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                               HOME.NIX                                        ║
# ║                                                                               ║
# ║  This is your MAIN CONFIGURATION file - the heart of your setup!             ║
# ║                                                                               ║
# ║  Here you define:                                                             ║
# ║    - 📦 Packages to install (like apt install, but declarative)              ║
# ║    - 📄 Dotfiles (configs are generated, not symlinked)                      ║
# ║    - 🔧 Program configurations (zsh, git, starship, etc.)                    ║
# ║                                                                               ║
# ║  After editing this file, run: home-manager switch --flake ~/dotfiles        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
{ config, pkgs, ... }:

{
  # ┌────────────────────────────────────────────────────────────────────────────┐
  # │ USER CONFIGURATION                                                          │
  # │                                                                             │
  # │ ⚠️  CHANGE THESE to match your system!                                      │
  # └────────────────────────────────────────────────────────────────────────────┘
  home.username = "harry";
  home.homeDirectory = "/home/harry";

  # Home Manager version - don't change this unless you know what you're doing
  home.stateVersion = "24.05";

  # Let Home Manager manage itself (recommended)
  programs.home-manager.enable = true;

  # ╔══════════════════════════════════════════════════════════════════════════════╗
  # ║                                                                               ║
  # ║                         📦 PACKAGES TO INSTALL                               ║
  # ║                                                                               ║
  # ║  This is the Nix-like experience you wanted!                                 ║
  # ║  Just add a package name here, run the switch command, and it's installed.  ║
  # ║                                                                               ║
  # ║  To search for packages: nix search nixpkgs <package-name>                  ║
  # ║  Or visit: https://search.nixos.org/packages                                ║
  # ║                                                                               ║
  # ╚══════════════════════════════════════════════════════════════════════════════╝
  home.packages = with pkgs; [
    # ╭─────────────────────────────────────────────────────────────────────────╮
    # │ 🐚 Shell & Terminal Tools                                                │
    # ╰─────────────────────────────────────────────────────────────────────────╯
    zsh                     # Modern shell (your main shell)
    starship                # Cross-shell prompt (the fancy prompt you use)
    zoxide                  # Smarter cd command (z command)
    fzf                     # Fuzzy finder (Ctrl+R for history search)
    lsd                     # Modern ls with icons
    bat                     # Modern cat with syntax highlighting
    eza                     # Modern ls alternative (optional, you have lsd)
    ripgrep                 # Fast grep (rg command)
    fd                      # Fast find alternative
    tree                    # Directory tree viewer
    htop                    # Process viewer
    btop                    # Beautiful resource monitor

    # ╭─────────────────────────────────────────────────────────────────────────╮
    # │ 🛠️  Development Tools                                                    │
    # ╰─────────────────────────────────────────────────────────────────────────╯
    git                     # Version control
    lazygit                 # Terminal UI for git
    neovim                  # Your editor
    gcc                     # C/C++ compiler
    gnumake                 # Make build tool
    cmake                   # CMake build system
    nodejs                  # Node.js runtime
    python3                 # Python 3
    
    # ╭─────────────────────────────────────────────────────────────────────────╮
    # │ 📊 System Info & Utilities                                               │
    # ╰─────────────────────────────────────────────────────────────────────────╯
    fastfetch               # System info (neofetch alternative)
    curl                    # HTTP client
    wget                    # File downloader
    unzip                   # Archive extraction
    jq                      # JSON processor
    ponysay

  ];

  # ╔══════════════════════════════════════════════════════════════════════════════╗
  # ║                                                                               ║
  # ║                         🐚 ZSH CONFIGURATION                                 ║
  # ║                                                                               ║
  # ║  This replaces your ~/.zshrc file completely!                                ║
  # ║  Home Manager generates it from this configuration.                          ║
  # ║                                                                               ║
  # ╚══════════════════════════════════════════════════════════════════════════════╝
  programs.zsh = {
    enable = true;
    
    # ┌────────────────────────────────────────────────────────────────────────┐
    # │ Shell Aliases - shortcuts for common commands                          │
    # └────────────────────────────────────────────────────────────────────────┘
    shellAliases = {
      # File listing with lsd (icons!)
      ls = "lsd";
      l = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      lt = "ls --tree";
      
      # Git shortcuts
      lg = "lazygit";
      gs = "git status";
      gp = "git push";
      gl = "git pull";
      
      # Navigation with zoxide
      cd = "z";
      
      # Quick edit configs
      ez = "nvim ~/dotfiles/home.nix";  # Edit this file!
      
      # Apply Home Manager changes (after editing home.nix)
      update = "home-manager switch --flake ~/dotfiles";
    };
    
    # ┌────────────────────────────────────────────────────────────────────────┐
    # │ Oh My Zsh - framework for managing zsh configuration                   │
    # └────────────────────────────────────────────────────────────────────────┘
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"           # Git aliases and functions
        "sudo"          # Press ESC twice to add sudo
        "web-search"    # Search from terminal (google foo)
        "copypath"      # Copy current path
        "copyfile"      # Copy file contents
      ];
      # Note: We use starship for the prompt, so no theme needed
    };
    
    # ┌────────────────────────────────────────────────────────────────────────┐
    # │ Plugins - extra functionality                                           │
    # │                                                                         │
    # │ These are installed automatically by Nix!                              │
    # └────────────────────────────────────────────────────────────────────────┘
    plugins = [
      {
        # Suggests commands as you type (grey text)
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        # Syntax highlighting (colors for valid/invalid commands)
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];
    
    # ┌────────────────────────────────────────────────────────────────────────┐
    # │ Init Extra - code that runs when zsh starts                            │
    # │                                                                         │
    # │ This is where we put custom functions and initializations.             │
    # │ It goes at the END of .zshrc                                           │
    # └────────────────────────────────────────────────────────────────────────┘
    initContent = ''
      # nix 
      if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
      fi

      # Show system info on terminal start
      fastfetch -c ~/.config/fastfetch/config.jsonc
      
      # Initialize starship prompt
      eval "$(starship init zsh)"
      
      # Initialize zoxide (smarter cd)
      eval "$(zoxide init zsh)"
      
      # ╭─────────────────────────────────────────────────────────────────────╮
      # │ Custom Functions                                                     │
      # ╰─────────────────────────────────────────────────────────────────────╯
      
      # Compile and run C++ file
      runcpp() {
        if [ -z "$1" ]; then
          echo "Usage: runcpp <filename.cpp>"
          return 1
        fi
        local SRC="$1"
        local OUT="''${SRC%.*}"
        g++ -std=c++17 -Wall "$SRC" -o "$OUT" && ./"$OUT"
      }
      
      # Create new competitive programming contest folder
      Contest() {
        local SRC="$HOME/cp/tmplcontest"
        local DEST=$1
        
        if [ -z "$DEST" ]; then
          echo "Usage: Contest <new_contest_name>"
          return 1
        fi
        
        if [ ! -d "$SRC" ]; then
          echo "Template folder '$SRC' does not exist."
          return 1
        fi
        
        if [ -d "$DEST" ]; then
          echo "Destination folder '$DEST' already exists."
          return 1
        fi
        
        cp -r "$SRC" "$DEST"
        cd "$DEST" || { echo "Directory not found: $DEST"; return 1; }
        echo "✅ New contest created: $DEST"
      }
    '';
    
    # ┌────────────────────────────────────────────────────────────────────────┐
    # │ Profile Extra - code that runs on login (before initExtra)             │
    # │                                                                         │
    # │ Good for environment variables and PATH modifications.                 │
    # └────────────────────────────────────────────────────────────────────────┘
    profileExtra = ''
      # Add local bin to PATH
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };

  # ╔══════════════════════════════════════════════════════════════════════════════╗
  # ║                                                                               ║
  # ║                         ⭐ STARSHIP PROMPT                                   ║
  # ║                                                                               ║
  # ║  Your beautiful prompt configuration!                                        ║
  # ║  This generates ~/.config/starship.toml                                      ║
  # ║                                                                               ║
  # ╚══════════════════════════════════════════════════════════════════════════════╝
  programs.starship = {
    enable = true;
    # Don't auto-init (we do it manually in zsh initExtra for control)
    enableZshIntegration = false;
  };
  
  # Starship config file (your existing config!)
  xdg.configFile."starship.toml".source = ./config/starship.toml;

  # ╔══════════════════════════════════════════════════════════════════════════════╗
  # ║                                                                               ║
  # ║                         🔧 GIT CONFIGURATION                                 ║
  # ║                                                                               ║
  # ║  This generates ~/.gitconfig                                                 ║
  # ║  Much cleaner than editing the file manually!                                ║
  # ║                                                                               ║
  # ╚══════════════════════════════════════════════════════════════════════════════╝
  programs.git = {
    enable = true;
    
    settings = {
      user.name = "Dreamerend3008";
      user.email = "79518618+Dreamerend3008@users.noreply.github.com";
      
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      
      # Better diffs
      core.pager = "less -FR";
      
      # Aliases
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --graph --decorate";
      };
    };
  };

  # ╔══════════════════════════════════════════════════════════════════════════════╗
  # ║                                                                               ║
  # ║                         📁 DOTFILES (Config Files)                           ║
  # ║                                                                               ║
  # ║  These copy/link your config files to the right places.                      ║
  # ║  xdg.configFile = files in ~/.config/                                        ║
  # ║  home.file = files in ~/                                                     ║
  # ║                                                                               ║
  # ╚══════════════════════════════════════════════════════════════════════════════╝

  # Neovim configuration (entire folder)
  xdg.configFile."nvim" = {
    source = ./config/nvim;
    recursive = true;  # Copy the whole directory
  };

  # Fastfetch configuration
  xdg.configFile."fastfetch" = {
    source = ./config/fastfetch;
    recursive = true;
  };

  # ╔══════════════════════════════════════════════════════════════════════════════╗
  # ║                                                                               ║
  # ║                         🏠 ENVIRONMENT VARIABLES                             ║
  # ║                                                                               ║
  # ╚══════════════════════════════════════════════════════════════════════════════╝
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "kitty";
  };
}
