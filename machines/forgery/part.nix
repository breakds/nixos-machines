{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.forgery = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      inputs.nixos-home.nixosModules.breakds-home

      self.nixosModules.graphical
      self.nixosModules.temporal
    ];
  };
}
