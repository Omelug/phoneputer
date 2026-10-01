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
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" "dialout" "feedbackd" ];
  };

  networking.networkmanager.enable = true;
  # Phosh uses wpa_supplicant via NetworkManager, not iwd
  networking.wireless.iwd.enable = false;

  services.xserver.desktopManager.phosh = {
    enable = true;
    user = "nixos";
    group = "users";
    phocConfig = {
      xwayland = "true";
      outputs.DSI-1.scale = 3;
    };
  };

  # Adreno 630 (SDM845) needs gles2 renderer and no hardware cursors
  systemd.services.phosh.environment = {
    WLR_RENDERER = "gles2";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

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

  services.journald.extraConfig = "Storage=persistent";

  environment.systemPackages = with pkgs; [
    phosh
    phosh-mobile-settings
    pkgs.alsa-ucm-conf
    sdm845-alsa-ucm
    git
    vim
    wget
    curl
    lazygit
    neovim
    kitty
  ];

  system.stateVersion = "25.11";
}
