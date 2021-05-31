{
  description = "Collection of my NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs?rev=f924460e91cba6473c5dc4b8ccb1a1cfc05bc2d7";

    # Use vital-modules, with the same nixpkgs
    vital-modules.url = "github:nixvital/vital-modules";
    vital-modules.inputs.nixpkgs.follows = "nixpkgs";

    # Use nixos-home, with the same nixpkgs
    nixos-home.url = "github:breakds/nixos-home";
    nixos-home.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, vital-modules, nixos-home, ... }: let
    chia-from-unstable = system: { config, ...}: let
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
      };
    in {
      nixpkgs.overlays = [
        (final: prev: {
          chia = pkgs-unstable.chia;
        })
      ];
    };
  in {
    nixosConfigurations = {
      welderhelper = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./welderhelper
        ];
      };

      gilgamesh = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./gilgamesh
        ];
      };

      rival = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./rival
        ];
      };

      zen = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          vital-modules.nixosModules.laptop-lids
          vital-modules.nixosModules.iphone-connect
          nixos-home.nixosModules.cassandra-home
          ./zen
        ];
      };

      hardstone = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          (chia-from-unstable "x86_64-linux")
          ./hardstone
        ];
      };
    };
  };
}
