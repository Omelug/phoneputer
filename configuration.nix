# Minimal configuration for OnePlus 6 (enchilada) NixOS Mobile
# Focus on essentials: SSH, wireless, and basic tools

{ config, pkgs, lib, ... }:

let
  ucm-env = "/run/current-system/sw/share/alsa/ucm2";

  sdm845-alsa-ucm =
    pkgs.runCommand "sdm845-alsa-ucm"
      {
        src = pkgs.fetchFromGitLab {
          name = "sdm845-alsa-ucm";
          owner = "sdm845-mainline";
          repo = "alsa-ucm-conf";
          rev = "1b8d290e5aa2ca16b7f2fa8d74910ad19ef88b3a";
          sha256 = "sha256-Kg4vxDrli/ffNeUwDBL5GfdJsbwFRPAUieQEsjVKADw=";
        };
        postPatch = "";
      }
      ''
        mkdir -p $out/share
        ln -s $src $out/share/alsa
      '';

  # Compile all GSettings schemas phosh needs into one directory.
  # Needed because: (1) phosh-session checks sm.puri.Phosh before launching
  # gnome-session, and (2) gnome-session starts phosh via systemd --user which
  # doesn't inherit XDG_DATA_DIRS from the phosh-session wrapper.
  phoshSchemas = pkgs.runCommand "phosh-gsettings-schemas" {
    nativeBuildInputs = [ pkgs.glib.dev ];
  } ''
    mkdir -p $out
    for pkg in \
      ${pkgs.gsettings-desktop-schemas} \
      ${pkgs.phosh} \
      ${pkgs.phoc} \
      ${pkgs.gtk3} \
      ${pkgs.gtk4} \
      ${pkgs.gnome-shell} \
      ${pkgs.gnome-control-center} \
      ${pkgs.feedbackd} \
      ${pkgs.gnome-session}; do
      find "$pkg/share/gsettings-schemas" -name "*.xml" 2>/dev/null | \
        while IFS= read -r f; do cp "$f" "$out/"; done || true
    done
    glib-compile-schemas "$out"
  '';
in
{
  nixpkgs.config.allowUnfree = true;

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.settings.PasswordAuthentication = true;

  users.users.root.password = "nixos";

  users.users.nixos = {
    isNormalUser = true;
    password = "nixos";
    shell = pkgs.fish;
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" "dialout" "feedbackd" ];
  };

  programs.fish.enable = true;

  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = false;

  hardware.bluetooth.enable = true;

  boot.kernelModules = [ "usbhid" "evdev" ];

  services.libinput.enable = true;

  services.xserver.desktopManager.phosh = {
    enable = true;
    user = "nixos";
    group = "users";
    phocConfig = {
      xwayland = "true";
      outputs.DSI-1.scale = 3;
    };
  };

  # Adreno 630 (SDM845): gles2 renderer + no hw cursors + compiled schemas
  systemd.services.phosh.environment = {
    WLR_RENDERER = "gles2";
    WLR_NO_HARDWARE_CURSORS = "1";
    GSETTINGS_SCHEMA_DIR = "${phoshSchemas}";
  };

  # Propagate to systemd user session so gnome-session's child phosh gets it too
  environment.variables.GSETTINGS_SCHEMA_DIR = "${phoshSchemas}";

  services.upower.enable = true;
  services.accounts-daemon.enable = true;
  services.geoclue2.enable = true;
  services.geoclue2.whitelistedAgents = [ "sm.puri.Phosh" ];

  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = with lib.gvariant; [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          clock-show-date = false;
        };
        "org/gnome/desktop/session" = {
          idle-delay = mkUint32 60;
        };
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-type = "nothing";
        };
        "sm/puri/phosh" = {
          osk-unfold-delay = 0.5;
          app-filter-mode = mkEmptyArray type.string;
          auth-app = "password";
        };
      };
    }
  ];

  # SDM845-specific audio: fix crackling and set UCM config
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    wireplumber.extraConfig = {
      alsa-sdm845 = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_input.*"; }
              { "node.name" = "~alsa_output.*"; }
            ];
            actions.update-props = {
              "audio.format" = "S16LE";
              "audio.rate" = 48000;
              "api.alsa.period-size" = 4096;
              "api.alsa.period-num" = 6;
              "api.alsa.headroom" = 512;
            };
          }
        ];
      };
    };
  };
  security.rtkit.enable = true;

  environment.pathsToLink = [ "/share/alsa/ucm2" ];
  environment.variables.ALSA_CONFIG_UCM2 = ucm-env;
  systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM2 = ucm-env;
  systemd.user.services.pipewire-pulse.environment.ALSA_CONFIG_UCM2 = ucm-env;
  systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM2 = ucm-env;

  virtualisation.waydroid.enable = true;  # Android kontejner pro APK

  services.journald.extraConfig = "Storage=persistent";

  environment.systemPackages = with pkgs; [
    # Mobile shell & settings
    phosh
    phosh-mobile-settings

    # Apps
    firefox-mobile   # mobile-optimized Firefox (Wayland)
    snapshot         # GNOME camera app (Wayland-native)
    vlc
    tor
    torsocks

    # Audio UCM for SDM845
    alsa-ucm-conf
    sdm845-alsa-ucm

    # CLI tools
    git
    vim
    wget
    curl
    iw           # wireless tools
    iproute2     # ip command

    # Terminal
    ghostty
    fish
  ];

  system.stateVersion = "25.11";
}
