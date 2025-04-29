{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.orchard = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      inputs.nixos-home.nixosModules.cassandra-home
      inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
      inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate

      self.nixosModules.graphical
      self.nixosModules.iphone-connect
      self.nixosModules.goose-ai
    ];
  };
}
