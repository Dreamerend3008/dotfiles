{
  description = "Harry's Multi-System Configuration - Works on NixOS, Ubuntu, and WSL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

  in
  {
    # ═══════════════════════════════════════════════════════════════════
    # 🏠 HOME MANAGER STANDALONE (Ubuntu/WSL)
    # ═══════════════════════════════════════════════════════════════════
    homeConfigurations."harry" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home.nix ];
    };

    # ═══════════════════════════════════════════════════════════════════
    # 🖥️  NIXOS SYSTEM (cuando uses NixOS)
    # ═══════════════════════════════════════════════════════════════════
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        # Tu configuración de sistema NixOS
        ./configuration.nix
        
        # Home Manager como módulo de NixOS
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.harry = ./home.nix;
        }
      ];
    };

    # Package por defecto para instalación fácil
    packages.${system}.default = home-manager.packages.${system}.default;
  };
}
