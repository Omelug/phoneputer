{
  description = "NixOS Mobile for OnePlus 6 (enchilada)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    mobile-nixos = {
      url = "github:mobile-nixos/mobile-nixos";
      flake = false;
    };

    # SDM845 mainline kernel tree (7.2.0), shallow pin
    sdm845-linux = {
      url = "git+https://codeberg.org/sdm845/linux?rev=949f86c36a31d8619ea1b18ea82d099cd752e86b";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, mobile-nixos, sdm845-linux, ... }:
    let
      system = "aarch64-linux";
    in {
      nixosConfigurations = {
        phoneputer = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit mobile-nixos sdm845-linux; };
          modules = [
            (import "${mobile-nixos}/lib/configuration.nix" { device = "oneplus-enchilada"; })
            ./configuration.nix
          ];
        };
      };
    };
}
