{
  description = "Collection of my NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Use vital-modules, with the same nixpkgs
    vital-modules.url = "github:nixvital/vital-modules";
    vital-modules.inputs.nixpkgs.follows = "nixpkgs";

    # Use nixos-home, with the same nixpkgs
    nixos-home.url = "github:breakds/nixos-home";
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
      machine-learning = import ./modules/machine-learning.nix {
        traintrack = inputs.traintrack;
      };
      iphone-connect = import ./modules/iphone-connect.nix;
      laptop = import ./modules/laptop.nix;
      steam = import ./modules/steam.nix;
    };

    nixosConfigurations = {
      samaritan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          self.nixosModules.iphone-connect
          nixos-home.nixosModules.breakds-home
          self.nixosModules.machine-learning
          ./machines/samaritan
        ];
      };

      malenia = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # ({ nixpkgs.overlays = [ inputs.wonder-devops.overlays.default ]; })
          vital-modules.nixosModules.foundation
          self.nixosModules.iphone-connect
          self.nixosModules.steam
          nixos-home.nixosModules.breakds-home
          self.nixosModules.machine-learning
          ./machines/malenia
        ];
      };

      "horizon.GAIL3" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          self.nixosModules.machine-learning
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
          self.nixosModules.machine-learning
          ./machines/octavian
          ({
            nixpkgs.overlays = [
              (final: prev: {
                www-breakds-org = inputs.www-breakds-org.defaultPackage."${final.system}";
              })
              # inputs.rapit.overlays.default
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
          self.nixosModules.machine-learning
          ./machines/learners/lothric
        ];
      };

      # The twin learner, Lorian (Elder Prince)
      lorian = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          self.nixosModules.machine-learning
          ./machines/learners/lorian
        ];
      };

      # The heavy learner
      radahn = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          self.nixosModules.machine-learning
          ./machines/learners/radahn
        ];
      };

      berry = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          self.nixosModules.laptop
          self.nixosModules.iphone-connect
          nixos-home.nixosModules.cassandra-home
          ./machines/berry
        ];
      };

      hand = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Get the community maintained framework baseline
          nixos-hardware.nixosModules.framework-12th-gen-intel
          vital-modules.nixosModules.foundation
          self.nixosModules.laptop
          self.nixosModules.iphone-connect
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

      armlet = nixpkgs.lib.nixosSystem {
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
      # Alternatively, see below (nix build .#liveISO for short).
      liveISO = nixpkgs.lib.nixosSystem {
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
      # nix build .#liveISO will build the ISO image
      liveISO = self.nixosConfigurations.liveISO.config.system.build.isoImage;
    };

    checks."x86_64-linux" = {
      octavian = self.nixosConfigurations.octavian.config.system.build.toplevel;
      malenia = self.nixosConfigurations.malenia.config.system.build.toplevel;
      hand = self.nixosConfigurations.hand.config.system.build.toplevel;
      liveISO = self.nixosConfigurations.liveISO.config.system.build.isoImage;      
    };
  };
}
