{
  description = "Collection of my NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

    # Use vital-modules, with the same nixpkgs
    vital-modules.url = "github:nixvital/vital-modules?rev=c308db6121905795429a0cd4763c64a544da4703";
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
