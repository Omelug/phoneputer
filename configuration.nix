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

  systemd.services.phosh = {
    after = [ "getty@tty1.service" "systemd-user-sessions.service" ];
    conflicts = [ "getty@tty1.service" ];
    wantedBy = [ "graphical.target" ];
    environment = {
      XDG_CURRENT_DESKTOP = "Phosh:GNOME";
      XDG_SESSION_DESKTOP = "phosh";
      XDG_SESSION_TYPE = "wayland";
      WLR_RENDERER = "gles2";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
    serviceConfig = {
      User = "nixos";
      Group = "users";
      PAMName = "login";
      ExecStart = "${pkgs.phosh}/bin/phosh-session";
      Restart = "on-failure";
      StandardError = "journal";
      StandardInput = "tty-fail";
      StandardOutput = "journal";
      TTYPath = "/dev/tty1";
      TTYReset = "yes";
      TTYVHangup = "yes";
      TTYVTDisallocate = "yes";
      UtmpIdentifier = "tty1";
      UtmpMode = "user";
      WorkingDirectory = "~";
    };
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


  environment.systemPackages = with pkgs; [
    phosh
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
