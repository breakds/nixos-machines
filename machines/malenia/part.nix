{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.malenia = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit (inputs) nixpkgs-unstable; };
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      inputs.nixos-home.nixosModules.breakds-home

      self.nixosModules.base-overlays
      self.nixosModules.graphical
      self.nixosModules.builder-cache-valley
      self.nixosModules.iphone-connect
      self.nixosModules.steam
      self.nixosModules.machine-learning
      self.nixosModules.flatpak
      self.nixosModules.wonder-devops
      self.nixosModules.gooseit
      self.nixosModules.prometheus-exporters
      self.nixosModules.ollama
    ];
  };
}
