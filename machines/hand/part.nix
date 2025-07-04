{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.hand = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      inputs.nixos-home.nixosModules.breakds-home
      inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series

      self.nixosModules.base-overlays
      self.nixosModules.laptop
      self.nixosModules.graphical
      self.nixosModules.iphone-connect
      self.nixosModules.steam
      self.nixosModules.flatpak
      self.nixosModules.localsend
      self.nixosModules.gooseit
    ];
  };
}
