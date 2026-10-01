# Minimal configuration for OnePlus 6 (enchilada) NixOS Mobile
# Focus on essentials: SSH, wireless, and basic tools

{ config, pkgs, ... }:

{
  # Allow unfree packages (needed for OnePlus firmware)
  nixpkgs.config.allowUnfree = true;

  # Enable SSH server (essential for mobile device access)
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes"; # For initial setup
  services.openssh.settings.PasswordAuthentication = true; # For initial setup

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  users.users.root.password = "nixos";

  services.upower.enable = true;
  services.accounts-daemon.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      terminal.vt = 1;
      default_session = {
        command = "${pkgs.phosh}/bin/phosh-session";
        user = "nixos";
      };
      initial_session = {
        command = "${pkgs.phosh}/bin/phosh-session";
        user = "nixos";
      };
    };
  };

  systemd.services.greetd.serviceConfig = {
    StartLimitBurst = 3;
    StartLimitIntervalSec = "60s";
  };

  # persistent journal — needed to read logs after rollback
  services.journald.extraConfig = "Storage=persistent";

  networking.networkmanager.enable = true;

  users.users.nixos = {
    isNormalUser = true;
    password = "nixos";
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" ];
  };

  programs.dconf.enable = true;


  # Minimal essential packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    lazygit
    asciiquarium
    neovim
    kitty
  ];

  system.stateVersion = "25.11";
} 
