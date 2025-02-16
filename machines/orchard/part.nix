{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosModules.overlay-nodejs-14 = let pkgs' = import inputs.nixpkgs-nvidia520 {
    system = "x86_64-linux";
    config.allowUnfree = true;
  }; in {
    nixpkgs.overlays = [
      (final: prev: {
        nodejs-14_x = pkgs'.nodejs-14_x;
      })
    ];
  };

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
      self.nixosModules.overlay-nodejs-14
      self.nixosModules.goose-ai
    ];
  };
}
