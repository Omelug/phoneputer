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

  # Phosh — mobile shell (touch-friendly, built for phones)
  services.phosh = {
    enable = true;
    user = "nixos";
    group = "users";
  };

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
