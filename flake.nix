{
  description = "Collection of my NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

    # Use vital-modules, with the same nixpkgs
    vital-modules.url = "github:nixvital/vital-modules?rev=64199edebb15563230370085229a3290b2914d66";
    vital-modules.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, vital-modules, ... }: {
    nixosConfigurations = {
      welderhelper = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          ./welderhelper
        ];
      };
    };
  };
}
