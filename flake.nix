{
  description = "Collection of my NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

    # Use vital-modules, with the same nixpkgs
    vital-modules.url = "github:nixvital/vital-modules?rev=c14d94843e3832552003a3253b7bec48bc8c1920";
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
