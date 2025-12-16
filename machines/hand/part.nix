{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.hand = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit (inputs) nixpkgs-unstable; };
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
      self.nixosModules.builder-cache-valley
      self.nixosModules.qmk
      self.nixosModules.sunshine      

      # Development Assistants
      self.nixosModules.gooseit
      self.nixosModules.coding-agent
    ];
  };
}
