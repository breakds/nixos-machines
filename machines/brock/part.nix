{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.brock = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      self.nixosModules.vital-base
      inputs.nixos-home.nixosModules.breakds-home

      self.nixosModules.base-overlays
      self.nixosModules.graphical
      self.nixosModules.iphone-connect
      self.nixosModules.flatpak
      self.nixosModules.prometheus-exporters
      self.nixosModules.syncthing      
    ];
  };
}
