{ config, pkgs,lib,... }:

{
    home.username = "harry";
    home.homeDirectory = "/home/harry";
    home.stateVersion = "24.05";
    news.display = "silent";

    programs.home-manager.enable = true;

    # Packages
    home.packages = with pkgs; [
        # shell & terminal
        zsh starship zoxide fzf lsd bat eza ripgrep fd tree htop btop yazi

        # development
        git lazygit tree-sitter gnumake cmake nodejs pkg-config

        
        # utilities
        fastfetch curl wget unzip jq ponysay zip sioyek
        
        # Desktop / Hyprland
        # NOTE: Hyprland tools (waybar, rofi, dunst, hyprlock, hypridle, swww,
        # hyprpaper, grim, slurp, wl-clipboard, cliphist, wlogout) are provided
        # by CachyOS system packages. Nix is only used as a dotfile manager.
        # Install them via: pacman -S waybar rofi-wayland dunst hyprlock hypridle
        #                   hyprpaper grim slurp wl-clipboard cliphist wlogout
        
        # python
        python311 # test pyenv
        
        # system libs
        stdenv.cc.cc.lib zlib
    ];

    # ZSH
    programs.zsh = {
        enable = true;

        shellAliases = {
                # File listing
                ls = "lsd"; l = "ls -l"; la = "ls -a"; lla = "ls -la"; lt = "ls --tree";
                # Git
                lg = "lazygit"; gs = "git status"; gp = "git push"; gl = "git pull";
                # Navigation
                cd = "z";
                # Config shortcuts
                ez = "nvim ~/dotfiles/home.nix";
                hy = "cd ~/.config/hypr/configs";
                uni = "cd /mnt/c/Users/juanb";
                # Update dotfiles commands 
                update = "if [ -f /etc/nixos/configuration.nix ]; then sudo nixos-rebuild switch --flake ~/dotfiles; else home-manager switch --flake ~/dotfiles; fi";
                update-home = "home-manager switch --flake ~/dotfiles";
                update-system = "sudo nixos-rebuild switch --flake ~/dotfiles";
        };

        oh-my-zsh = {
          enable = true;
          plugins = [ "git" "sudo" "web-search" "copypath" "copyfile" ];
        };

        plugins = [
          { name = "zsh-autosuggestions"; src = pkgs.zsh-autosuggestions; file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh"; }
          { name = "zsh-syntax-highlighting"; src = pkgs.zsh-syntax-highlighting; file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; }
        ];

        initContent = ''
          export PATH="$PATH:/snap/bin"
          export PATH="$HOME/.npm-global/bin:$PATH"
          # Nix env (standalone)
          if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi

          # Load secrets (API keys, tokens) — file is gitignored
          if [ -f "$HOME/.secrets" ]; then source "$HOME/.secrets"; fi

          fastfetch -c ~/.config/fastfetch/config.jsonc
          
          eval "$(starship init zsh)"
          eval "$(zoxide init zsh)"

          # Free memory for CP
          ulimit -s 1048576
          
          # Custom Functions
          runcpp() {
            if [ -z "$1" ]; then echo "Usage: runcpp <filename.cpp>"; return 1; fi
            g++ -std=c++17 -Wall "$1" -o "''${1%.*}" && env LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:$LD_LIBRARY_PATH" ./"''${1%.*}"
          }

          tmpl(){
            local SRC="$HOME/dotfiles/utils/template.cpp"
            local DEST=$1
            if [ -z "$DEST" ]; then echo "Usage: tmpl <file_name>"; return 1; fi
            if [ ! -f "$SRC" ]; then echo "Template file does not exist"; return 1; fi
            cp "$SRC" "$DEST"
            nvim "$DEST"
          }
        '';
        profileExtra = '' export PATH="$HOME/.local/bin:$PATH" '';
    };

    # Starship
    programs.starship = { enable = true; enableZshIntegration = false; };
    xdg.configFile."starship.toml".source = ./config/starship.toml;

    # Git
    programs.git = {
        enable = true;
        settings = {
          user.name = "Dreamerend3008";
          user.email = "79518618+Dreamerend3008@users.noreply.github.com";
          init.defaultBranch = "main";
          pull.rebase = false;
          push.autoSetupRemote = true;
          core.pager = "less -FR";
          alias = { st = "status"; co = "checkout"; br = "branch"; ci = "commit"; lg = "log --oneline --graph --decorate"; };
        };
    };

    # Dotfiles
    xdg.configFile."kitty" = { source = ./config/kitty; recursive = true; };
    xdg.configFile."ghostty" = { source = ./config/ghostty; recursive = true; };
    xdg.configFile."nvim" = { source = ./config/nvim; recursive = true; };
    xdg.configFile."clangd/config.yaml".source = ./config/clangd/config.yaml;
    xdg.configFile."fastfetch" = { source = ./config/fastfetch; recursive = true; };
    xdg.configFile."waybar" = { source = ./config/waybar; recursive = true; };
    xdg.configFile."rofi" = { source = ./config/rofi; recursive = true; };
    xdg.configFile."dunst" = { source = ./config/dunst; recursive = true; };
    xdg.configFile."wlogout" = { source = ./config/wlogout; recursive = true; };
    
    # Hyprland
    xdg.configFile."hypr" = { 
        source = ./config/hypr; 
        recursive = true; 
        onChange = "env -u LD_LIBRARY_PATH /usr/bin/hyprctl reload || true";
    };

    # Pi (terminal AI agent)
    # settings.json is linked directly to the dotfiles repo so changes made from
    # Pi's /settings screen persist across restarts and also stay in ~/dotfiles.
    # Keep the selected theme in settings.json authoritative so startup doesn't
    # fall back to a different default theme and make the borders look darker.
    home.file.".pi/agent/models.json".source = ./config/pi/models.json;
    home.file.".pi/agent/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/pi/settings.json";
    home.file.".pi/agent/keybindings.json".source = ./config/pi/keybindings.json;
    home.file.".pi/agent/extensions/web-search-extension.ts".source = ./config/pi/web-search-extension.ts;
    home.file.".pi/agent/extensions/model-cost-extension.ts".source = ./config/pi/model-cost-extension.ts;
    home.file.".pi/agent/extensions/usage-extension.ts".source = ./config/pi/usage-extension.ts;
    home.file.".pi/agent/skills" = { source = ./config/pi/skills; recursive = true; };
    home.file.".pi/agent/prompts" = { source = ./config/pi/prompts; recursive = true; };
    home.file.".pi/agent/themes/cachyos-neon.json".source = ./config/pi/themes/cachyos-neon.json;
    home.file.".pi/agent/themes/bearded-coffee-night.json".source = ./config/pi/themes/bearded-coffee-night.json;
    home.file.".pi/agent/themes/bearded-coffee-light.json".source = ./config/pi/themes/bearded-coffee-light.json;

    # Generate auth.json at activation from env var (keeps key out of repo)
    home.activation.piAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PI_DIR="$HOME/.pi/agent"
      mkdir -p "$PI_DIR"
      if [ -f "$HOME/.secrets" ]; then
        . "$HOME/.secrets"
      fi
      if [ -n "$AZURE_OPENAI_API_KEY" ]; then
        cat > "$PI_DIR/auth.json" <<EOF
{
  "azure-foundry": {
    "type": "api_key",
    "key": "$AZURE_OPENAI_API_KEY"
  }
}
EOF
        chmod 600 "$PI_DIR/auth.json"
      fi
    '';

    # Env variables
    home.sessionVariables = {
            EDITOR = "nvim";
            VISUAL = "nvim";
            NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };
    home.sessionPath = [ "$HOME/.npm-global/bin" ];

    home.language = {
      base = "en_US.UTF-8";
      address = "en_US.UTF-8";
      measurement = "en_US.UTF-8";
      monetary = "en_US.UTF-8";
      name = "en_US.UTF-8";
      numeric = "en_US.UTF-8";
      paper = "en_US.UTF-8";
      telephone = "en_US.UTF-8";
      time = "en_US.UTF-8";
      ctype = "en_US.UTF-8";
      collate = "en_US.UTF-8";
      messages = "en_US.UTF-8";
    };
}

