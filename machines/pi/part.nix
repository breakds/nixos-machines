{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations = {

    armlet = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./armlet
        ../../modules/vital-base/main-user.nix
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
        self.nixosModules.graphical
      ];
    };

    amber = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./amber
        ../../modules/vital-base/main-user.nix        
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
        self.nixosModules.graphical
        self.nixosModules.prometheus-exporters
      ];
    };
  };
}
