{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.ghostberry = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      inputs.nixos-home.nixosModules.breakds-home

      self.nixosModules.laptop
      self.nixosModules.graphical
      self.nixosModules.iphone-connect
      self.nixosModules.steam
      self.nixosModules.flatpak
      self.nixosModules.goose-ai
      self.nixosModules.wonder-datahub
    ];
  };
}
