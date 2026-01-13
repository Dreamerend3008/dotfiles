# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                         CONFIGURATION.NIX                                     ║
# ║                                                                               ║
# ║  Configuración de SISTEMA para NixOS (no para Ubuntu/WSL)                   ║
# ║  Este archivo solo se usa cuando estás en NixOS nativo.                      ║
# ║                                                                               ║
# ║  Aquí defines:                                                                ║
# ║    - Bootloader, kernel, drivers                                              ║
# ║    - Servicios del sistema (networking, ssh, etc.)                           ║
# ║    - Usuarios y grupos                                                        ║
# ║    - Configuración de hardware                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

{ config, pkgs, ... }:

{
  imports = [
    # ⚠️  IMPORTANTE: Incluir tu hardware-configuration.nix
    # Este archivo es generado por NixOS durante la instalación
    # y contiene la configuración específica de tu hardware
    ./hardware-configuration.nix
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # 🥾 BOOTLOADER
  # ═══════════════════════════════════════════════════════════════════════════
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # 🌐 NETWORKING
  # ═══════════════════════════════════════════════════════════════════════════
  networking.hostName = "nixos"; # Cambia esto al nombre de tu máquina
  networking.networkmanager.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # 🌍 INTERNACIONALIZACIÓN
  # ═══════════════════════════════════════════════════════════════════════════
  time.timeZone = "America/Bogota";
  
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_CO.UTF-8";
    LC_IDENTIFICATION = "es_CO.UTF-8";
    LC_MEASUREMENT = "es_CO.UTF-8";
    LC_MONETARY = "es_CO.UTF-8";
    LC_NAME = "es_CO.UTF-8";
    LC_NUMERIC = "es_CO.UTF-8";
    LC_PAPER = "es_CO.UTF-8";
    LC_TELEPHONE = "es_CO.UTF-8";
    LC_TIME = "es_CO.UTF-8";
  };
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  servies.desktopManager.plasna6.enable = true;





  # ═══════════════════════════════════════════════════════════════════════════
  # 👤 USUARIOS
  # ═══════════════════════════════════════════════════════════════════════════
  users.users.harry = {
    isNormalUser = true;
    description = "Harry";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
    # Si quieres setear contraseña inicial:
    # initialPassword = "changeme";
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # 📦 PAQUETES DEL SISTEMA (nivel sistema, no usuario)
  # ═══════════════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # 🐚 HABILITAR ZSH A NIVEL SISTEMA
  # ═══════════════════════════════════════════════════════════════════════════
  programs.zsh.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # 🔧 SERVICIOS DEL SISTEMA
  # ═══════════════════════════════════════════════════════════════════════════
  
  # SSH (opcional)
  services.openssh.enable = true;

  # Docker (opcional)
  # virtualisation.docker.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # ⚙️  NEATRIX - Habilita flakes y comandos nix
  # ═══════════════════════════════════════════════════════════════════════════
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Garbage collection automático (limpia paquetes viejos)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # 🔒 FIREWALL
  # ═══════════════════════════════════════════════════════════════════════════
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # ═══════════════════════════════════════════════════════════════════════════
  # 📌 VERSION DEL SISTEMA
  # ═══════════════════════════════════════════════════════════════════════════
  # No cambies esto después de la instalación inicial
  system.stateVersion = "24.05";
}
