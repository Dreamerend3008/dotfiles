# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              FLAKE.NIX                                        ║
# ║                                                                               ║
# ║  This is the ENTRY POINT of your Nix configuration.                          ║
# ║  Think of it as a "package.json" for your entire system.                     ║
# ║                                                                               ║
# ║  It defines:                                                                  ║
# ║    - inputs: Where to get packages from (like npm registries)                ║
# ║    - outputs: What this flake produces (your home configuration)             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
{
  description = "Harry's Home Manager Configuration";

  # ┌────────────────────────────────────────────────────────────────────────────┐
  # │ INPUTS - External dependencies (like package sources)                       │
  # │                                                                             │
  # │ These are the "repositories" Nix will fetch packages from.                 │
  # │ You can pin versions, use different branches, etc.                         │
  # └────────────────────────────────────────────────────────────────────────────┘
  inputs = {
    # Main package repository - "nixpkgs" is like the apt/brew repository
    # "nixpkgs-unstable" has the latest packages (updated frequently)
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Home Manager - manages your dotfiles and user packages
    # This is what lets us define everything in one place!
    home-manager = {
      url = "github:nix-community/home-manager";
      # This line says "use the same nixpkgs version as above"
      # Keeps everything in sync and avoids conflicts
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ┌────────────────────────────────────────────────────────────────────────────┐
  # │ OUTPUTS - What this flake produces                                          │
  # │                                                                             │
  # │ This is where we define our actual configuration.                          │
  # │ The "homeConfigurations" attribute is what Home Manager looks for.         │
  # └────────────────────────────────────────────────────────────────────────────┘
  outputs = { nixpkgs, home-manager, ... }: 
  let
    # ╭─────────────────────────────────────────────────────────────────────────╮
    # │ SYSTEM CONFIGURATION                                                     │
    # │                                                                          │
    # │ Change "x86_64-linux" to "aarch64-linux" for ARM (like Raspberry Pi)    │
    # │ For macOS: "x86_64-darwin" or "aarch64-darwin" (Apple Silicon)          │
    # ╰─────────────────────────────────────────────────────────────────────────╯
    system = "x86_64-linux";
    
    # Load the package set for our system
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # ╭─────────────────────────────────────────────────────────────────────────╮
    # │ HOME CONFIGURATIONS                                                      │
    # │                                                                          │
    # │ You can have multiple configurations for different machines!            │
    # │ Example: "harry@desktop", "harry@laptop", "harry@work"                  │
    # │                                                                          │
    # │ ⚠️  IMPORTANT: Change "harry" to YOUR username!                          │
    # ╰─────────────────────────────────────────────────────────────────────────╯
    homeConfigurations."harry" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      
      # This points to your main configuration file
      # All the magic happens in home.nix!
      modules = [ ./home.nix ];
    };

    # ┌────────────────────────────────────────────────────────────────────────┐
    # │ DEFAULT PACKAGE - Makes installation easier                             │
    # │                                                                         │
    # │ This lets you run: nix run . -- switch --flake .                       │
    # │ Instead of installing home-manager separately first                     │
    # └────────────────────────────────────────────────────────────────────────┘
    packages.${system}.default = home-manager.packages.${system}.default;
  };
}
