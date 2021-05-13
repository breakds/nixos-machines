{
  description = "Collection of my NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

    # Use vital-modules, with the same nixpkgs
    vital-modules.url = "github:nixvital/vital-modules?rev=fac1ab14b2d53708afaba654bd8503fa9456659e";
    vital-modules.inputs.nixpkgs.follows = "nixpkgs";

    # Use nixos-home, with the same nixpkgs
    nixos-home.url = "github:breakds/nixos-home?rev=a2c05fc7fcac090b756086eba8b0762178391c30";
    nixos-home.inputs.nixpkgs.follows = "nixpkgs";

    # chiafan-workforce, with the same nixpkgs
    chiafan-workforce.url = "github:chiafan-org/chiafan-workforce?rev=3808e7bd06427adfee14399a7f1270b2dc8a1889";
    chiafan-workforce.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, vital-modules, nixos-home, chiafan-workforce, ... }: {
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
          ({ pkgs, ... }: {
            environment.systemPackages = [ pkgs.python3Packages.chiafan-workforce ];
          })
           vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./hardstone
        ];
      };
    };
  };
}

