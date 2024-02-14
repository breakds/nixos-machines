{
  description = "Collection of my NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    nixpkgs-nvidia520.url = "github:NixOS/nixpkgs?rev=c1254eebab9a7257e978af1009d9ba2133befcec";

    nixpkgs-2311-pre.url = "github:NixOS/nixpkgs?rev=fdd898f8f79e8d2f99ed2ab6b3751811ef683242";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Use vital-modules, with the same nixpkgs
    vital-modules.url = "github:nixvital/vital-modules";
    vital-modules.inputs.nixpkgs.follows = "nixpkgs";

    # Use nixos-home, with the same nixpkgs
    nixos-home.url = "github:breakds/nixos-home";
    nixos-home.inputs.nixpkgs.follows = "nixpkgs";
    nixos-home.inputs.home-manager.follows = "home-manager";

    www-breakds-org.url = "github:breakds/www.breakds.org";
    www-breakds-org.inputs.nixpkgs.follows = "nixpkgs";

    wonder-devops.url = "git+ssh://git@github.com/quant-wonderland/devops-tools";
    wonder-devops.inputs.nixpkgs.follows = "nixpkgs";

    traintrack.url = "github:breakds/traintrack";
    traintrack.inputs.nixpkgs.follows = "nixpkgs";

    rapit.url = "git+ssh://git@github.com/breakds/rapit";
    rapit.inputs.nixpkgs.follows = "nixpkgs";

    interm.url = "git+ssh://git@github.com/breakds/interm";
    interm.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, vital-modules, nixos-home, ... }@inputs: {
    nixosModules = {
      graphical = import ./modules/graphical;
      machine-learning = import ./modules/machine-learning.nix {
        traintrack = inputs.traintrack;
      };
      iphone-connect = import ./modules/iphone-connect.nix;
      laptop = import ./modules/laptop.nix;
      steam = import ./modules/steam.nix;
      steam-run = import ./modules/steam-run.nix;
      flatpak = import ./modules/flatpak.nix;

      horizon-home = import ./users/horizon;
      mito-home = import ./users/mito;

      downgrade-to-nvidia520 = {config, lib, pkgs, ...}:
        let pkgs' = import inputs.nixpkgs-nvidia520 {
              system = "x86_64-linux";
              config.allowUnfree = true;
            }; in {
              boot.kernelPackages = pkgs'.linuxPackages;
              hardware.nvidia.package = pkgs'.linuxPackages.nvidiaPackages.latest;
            };

      # Sadly nodejs-14_x reaches EOL is removed. Here we resurrect it.
      overlay-nodejs-14 = {config, lib, pkgs, ...}:
        let pkgs' = import inputs.nixpkgs-nvidia520 {
              system = "x86_64-linux";
              config.allowUnfree = true;
            }; in {
              nixpkgs.overlays = [
                (finale: prev: {
                  nodejs-14_x = pkgs'.nodejs-14_x;
                })
              ];
            };
    };

    nixosConfigurations = {
      samaritan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          self.nixosModules.graphical
          self.nixosModules.iphone-connect
          nixos-home.nixosModules.breakds-home
          self.nixosModules.machine-learning
          self.nixosModules.flatpak          
          self.nixosModules.downgrade-to-nvidia520
          self.nixosModules.steam-run
          ./machines/samaritan
        ];
      };

      malenia = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # ({ nixpkgs.overlays = [ inputs.wonder-devops.overlays.default ]; })
          vital-modules.nixosModules.foundation
          self.nixosModules.graphical          
          self.nixosModules.iphone-connect
          # TODO(breakds): Make steam great again.
          # self.nixosModules.steam
          nixos-home.nixosModules.breakds-home
          self.nixosModules.machine-learning
          self.nixosModules.flatpak
          ./machines/malenia
        ];
      };

      "horizon.GAIL3" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          self.nixosModules.graphical          
          nixos-home.nixosModules.breakds-home
          self.nixosModules.machine-learning
          ./machines/horizon/GAIL3
        ];
      };

      octavian = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          self.nixosModules.graphical          
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
          self.nixosModules.graphical          
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
          self.nixosModules.graphical          
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
          self.nixosModules.graphical          
          nixos-home.nixosModules.breakds-home
          self.nixosModules.machine-learning
          ./machines/learners/radahn
        ];
      };

      berry = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          self.nixosModules.graphical          
          self.nixosModules.laptop
          self.nixosModules.iphone-connect
          nixos-home.nixosModules.cassandra-home
          ./machines/berry
        ];
      };

      orchard = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
          nixos-hardware.nixosModules.common-cpu-amd-pstate
          vital-modules.nixosModules.foundation
          self.nixosModules.graphical          
          self.nixosModules.iphone-connect
          self.nixosModules.overlay-nodejs-14
          nixos-home.nixosModules.cassandra-home
          ./machines/orchard
        ];
      };

      hand = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Get the community maintained framework baseline
          nixos-hardware.nixosModules.framework-12th-gen-intel
          vital-modules.nixosModules.foundation
          self.nixosModules.graphical          
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
          self.nixosModules.graphical
          ./machines/medea
        ];
      };

      # Raspberry Pi 4B
      armlet = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          vital-modules.nixosModules.users
          self.nixosModules.graphical          
          # nixos-home.nixosModules.breakds-home
          ./machines/pi/armlet
        ];
      };

      # Raspberry Pi 4B
      emerald = inputs.nixpkgs-2311-pre.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          vital-modules.nixosModules.users
          self.nixosModules.graphical          
          ./machines/pi/emerald
        ];
      };

      # Machine for robot deployment, ITX
      rei = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          self.nixosModules.graphical
          nixos-home.nixosModules.breakds-home
          self.nixosModules.machine-learning
          self.nixosModules.downgrade-to-nvidia520
          ./machines/rei
        ];
      };

      # Smart Display
      gargoyle = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({
            nixpkgs.overlays = [
              inputs.interm.overlays.default
            ];
          })
          vital-modules.nixosModules.foundation
          self.nixosModules.graphical
          ./machines/gargoyle
        ];
      };

      # Laptop for robot deployment
      hyaku = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Unlike the others, the home-manager configuration for hyaku is
          # managed in this repo.
          inputs.home-manager.nixosModules.home-manager
          self.nixosModules.horizon-home
          self.nixosModules.mito-home
          vital-modules.nixosModules.foundation
          self.nixosModules.graphical
          self.nixosModules.laptop
          self.nixosModules.steam-run
          ./machines/hyaku
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
      inherit (pkgs) shuriken medea-clipper robot-deployment-suite;
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
