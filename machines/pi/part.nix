{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations = {

    armlet = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./armlet
        inputs.vital-modules.nixosModules.users
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
        self.nixosModules.graphical
      ];
    };

    amber = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./amber
        inputs.vital-modules.nixosModules.users
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
        self.nixosModules.graphical
      ];
    };
  };
}
