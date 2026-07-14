{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.ghostberry = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit (inputs) nixpkgs-unstable; };
    modules = [
      ./.
      self.nixosModules.vital-base

      inputs.nixos-home.nixosModules.breakds-home
      inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
      inputs.nixos-hardware.nixosModules.common-gpu-amd

      self.nixosModules.base-overlays
      self.nixosModules.laptop
      self.nixosModules.graphical
      self.nixosModules.iphone-connect
      self.nixosModules.niri
      self.nixosModules.localsend
      self.nixosModules.tiny-share-client
      self.nixosModules.post-box

      # Development Assistants
      self.nixosModules.coding-agent
    ];
  };
}
