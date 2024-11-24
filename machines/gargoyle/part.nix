{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.gargoyle = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
    ];
  };
}
