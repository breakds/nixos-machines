{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.brock = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      self.nixosModules.vital-base
      inputs.nixos-home.nixosModules.breakds-home

      self.nixosModules.base-overlays
      self.nixosModules.graphical
      self.nixosModules.iphone-connect
      self.nixosModules.steam
      self.nixosModules.niri
      self.nixosModules.flatpak
      self.nixosModules.localsend
      self.nixosModules.tiny-share-client
      self.nixosModules.prometheus-exporters
      self.nixosModules.syncthing
      self.nixosModules.qmk
      self.nixosModules.arduino

      # Development Assistants
      self.nixosModules.coding-agent
    ];
  };
}
