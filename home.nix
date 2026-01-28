# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                               HOME.NIX                                        ║
# ║                                                                               ║
# ║  Configuración COMPARTIDA entre NixOS, Ubuntu y WSL                          ║
# ║  Este archivo funciona en cualquier sistema!                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

{ config, pkgs, ... }:

{
  # ┌────────────────────────────────────────────────────────────────────────────┐
  # │ USER CONFIGURATION                                                          │
  # │                                                                             │
  # │ ⚠️  CAMBIAR SOLO EN STANDALONE (Ubuntu/WSL)                                │
  # │ En NixOS esto lo maneja configuration.nix                                  │
  # └────────────────────────────────────────────────────────────────────────────┘
  home.username = "harry";
  home.homeDirectory = "/home/harry";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # 📦 PAQUETES DE USUARIO
  # ═══════════════════════════════════════════════════════════════════════════
  home.packages = with pkgs; [
    # programs

    # 🐚 Shell & Terminal
    zsh
    starship
    zoxide
    fzf
    lsd
    bat
    eza
    ripgrep
    fd
    tree
    htop
    btop

    # 🛠️  Development
    git
    lazygit
    neovim
    tree-sitter
    gcc
    gnumake
    cmake
    nodejs
    python3
    
    # 📊 Utilities
    fastfetch
    curl
    wget
    unzip
    jq
    ponysay
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # 🐚 ZSH CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  programs.zsh = {
    enable = true;
    
    shellAliases = {
      # File listing
      ls = "lsd";
      l = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      lt = "ls --tree";
      
      # Git
      lg = "lazygit";
      gs = "git status";
      gp = "git push";
      gl = "git pull";
      
      # Navigation
      cd = "z";
      
      # Config shortcuts
      ez = "nvim ~/dotfiles/home.nix";
      hy = "cd ~/.config/hypr/";

      # Update commands (detecta automáticamente el sistema)
      update = "if [ -f /etc/nixos/configuration.nix ]; then sudo nixos-rebuild switch --flake ~/dotfiles; else home-manager switch --flake ~/dotfiles; fi";
      update-home = "home-manager switch --flake ~/dotfiles";
      update-system = "sudo nixos-rebuild switch --flake ~/dotfiles";
    };
    
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "web-search"
        "copypath"
        "copyfile"
      ];
    };
    
    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];
    
    initContent = ''
      # Nix environment (solo necesario en standalone)
      if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
      fi

      # System info
      fastfetch -c ~/.config/fastfetch/config.jsonc
      
      # Prompt & tools
      eval "$(starship init zsh)"
      eval "$(zoxide init zsh)"

      # npm 
      export PATH=~/.npm-global/bin:$PATH

      # ═══════════════════════════════════════════════════════════════
      # Custom Functions
      # ═══════════════════════════════════════════════════════════════
      
      # Compile and run C++
      runcpp() {
        if [ -z "$1" ]; then
          echo "Usage: runcpp <filename.cpp>"
          return 1
        fi
        local SRC="$1"
        local OUT="''${SRC%.*}"
        g++ -std=c++17 -Wall "$SRC" -o "$OUT" && ./"$OUT"
      }
      
      # Create contest folder
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
    
    profileExtra = ''
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # ⭐ STARSHIP
  # ═══════════════════════════════════════════════════════════════════════════
  programs.starship = {
    enable = true;
    enableZshIntegration = false;
  };
  
  xdg.configFile."starship.toml".source = ./config/starship.toml;

  # ═══════════════════════════════════════════════════════════════════════════
  # 🔧 GIT
  # ═══════════════════════════════════════════════════════════════════════════
  
    programs.git = {
    enable = true;
    settings = {
      user.name = "Dreamerend3008";
      user.email = "79518618+Dreamerend3008@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      core.pager = "less -FR";
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --graph --decorate";
      };
    };
  };


  # ═══════════════════════════════════════════════════════════════════════════
  # 📁 DOTFILES
  # ═══════════════════════════════════════════════════════════════════════════
  xdg.configFile."nvim" = {
    source = ./config/nvim;
    recursive = true;
  };

  xdg.configFile."fastfetch" = {
    source = ./config/fastfetch;
    recursive = true;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # 🏠 ENVIRONMENT VARIABLES
  # ═══════════════════════════════════════════════════════════════════════════
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
