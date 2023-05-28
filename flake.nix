{
  description = "Collection of my NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs2305.url = "github:NixOS/nixpkgs/nixos-23.05";    
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Use vital-modules, with the same nixpkgs
    vital-modules.url = "github:nixvital/vital-modules";
    vital-modules.inputs.nixpkgs.follows = "nixpkgs";

    # Use nixos-home, with the same nixpkgs
    nixos-home.url = "github:breakds/nixos-home/dev/23.05";
    nixos-home.inputs.nixpkgs.follows = "nixpkgs";

    www-breakds-org.url = "github:breakds/www.breakds.org";
    www-breakds-org.inputs.nixpkgs.follows = "nixpkgs";

    wonder-devops.url = "git+ssh://git@github.com/quant-wonderland/devops-tools";
    wonder-devops.inputs.nixpkgs.follows = "nixpkgs";

    traintrack.url = "github:breakds/traintrack";
    traintrack.inputs.nixpkgs.follows = "nixpkgs";

    rapit.url = "git+ssh://git@github.com/breakds/rapit";
    rapit.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, vital-modules, nixos-home, ... }@inputs: {
    nixosModules = {
      ml-capable = {
        nixpkgs.overlays = [ inputs.traintrack.overlays.default ];
        vital.programs.machine-learning.enable = true;
      };
    };

    nixosConfigurations = {
      samaritan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          vital-modules.nixosModules.iphone-connect
          vital-modules.nixosModules.docker
          nixos-home.nixosModules.breakds-home
          self.nixosModules.ml-capable
          ./machines/samaritan
        ];
      };

      malenia = inputs.nixpkgs2305.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # ({ nixpkgs.overlays = [ inputs.wonder-devops.overlays.default ]; })
          vital-modules.nixosModules.foundation
          vital-modules.nixosModules.iphone-connect
          vital-modules.nixosModules.docker
          nixos-home.nixosModules.breakds-home
          self.nixosModules.ml-capable
          ./machines/malenia
        ];
      };

      "horizon.GAIL3" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          self.nixosModules.ml-capable
          ./machines/horizon/GAIL3
        ];
      };

      "horizon.zero" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./machines/horizon/zero
        ];
      };

      octavian = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          vital-modules.nixosModules.docker
          self.nixosModules.ml-capable
          ./machines/octavian
          ({
            nixpkgs.overlays = [
              (final: prev: {
                www-breakds-org = inputs.www-breakds-org.defaultPackage."${final.system}";
              })
              inputs.rapit.overlays.default
            ];
          })
        ];
      };

      # The twin learner, Lothric (Younger Prince)
      lothric = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          self.nixosModules.ml-capable
          ./machines/learners/lothric
        ];
      };

      # The twin learner, Lorian (Elder Prince)
      lorian = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          self.nixosModules.ml-capable
          ./machines/learners/lorian
        ];
      };

      # The heavy learner
      radahn = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          self.nixosModules.ml-capable
          ./machines/learners/radahn
        ];
      };

      berry = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          vital-modules.nixosModules.laptop
          vital-modules.nixosModules.iphone-connect
          nixos-home.nixosModules.cassandra-home
          ./machines/berry
        ];
      };

      hand = inputs.nixpkgs2305.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Get the community maintained framework baseline
          nixos-hardware.nixosModules.framework-12th-gen-intel
          vital-modules.nixosModules.foundation
          vital-modules.nixosModules.laptop
          vital-modules.nixosModules.iphone-connect
          nixos-home.nixosModules.breakds-home
          ./machines/hand
        ];
      };

      medea = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./machines/medea
        ];
      };

      armlet = inputs.nixpkgs-unstable.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          vital-modules.nixosModules.users
          vital-modules.nixosModules.graphical
          # nixos-home.nixosModules.breakds-home
          ./machines/pi/armlet
        ];
      };

      # Containers
      fortress = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./containers/fortress.nix
        ];
      };

      # How to build this live:
      # nix build .#nixosConfigurations.liveISO.config.system.build.isoImage
      liveISO = inputs.nixpkgs-unstable.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # The base image that has gnome.
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          ./machines/livecd/with-nvidia.nix
        ];
      };
    };

    # This is mainly for debugging and experiments purpose. Use this
    # to expose packages that you want to debug.
    packages."x86_64-linux" = let pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [
        (import ./base/overlays)
      ];
    }; in {
      inherit (pkgs) shuriken medea-clipper;
    };
  };
}
