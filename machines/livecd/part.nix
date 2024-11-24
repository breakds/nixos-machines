{ inputs, ... }:

let self = inputs.self;
    nixpkgs = inputs.nixpkgs;

in {
  flake.nixosConfigurations = {

    # How to build this live:
    # nix build .#nixosConfigurations.liveCD.config.system.build.isoImage
    # Alternatively, see below (nix build .#liveCD for short).
    liveCD = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # The base image that has gnome.
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
        ./with-nvidia.nix
      ];
    };

    liveStandardCD = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # The base image that has gnome.
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
        ./standard.nix
      ];
    };
    
  };
}
