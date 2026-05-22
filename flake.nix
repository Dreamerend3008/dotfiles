{
  description = "Harry's Multi-System Configuration";

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
    # 🏠 HOME MANAGER STANDALONE
    # ═══════════════════════════════════════════════════════════════════
    homeConfigurations."harry" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home.nix ];
    };

    # Package por defecto para instalación fácil
    packages.${system}.default = home-manager.packages.${system}.default;
  };
}
