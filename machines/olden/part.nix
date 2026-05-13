{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.olden = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      self.nixosModules.vital-base
      inputs.nixos-home.nixosModules.breakds-home

      self.nixosModules.base-overlays
    ];
  };
}
