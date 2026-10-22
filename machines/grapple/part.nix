{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.grapple = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit (inputs) nixpkgs-unstable; };
    modules = [
      ./.
      ../../base/breakds-laptop.nix
      self.nixosModules.vital-base
      inputs.nixos-home.nixosModules.breakds-home
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
      inputs.lanzaboote.nixosModules.lanzaboote

      self.nixosModules.base-overlays
      self.nixosModules.laptop
      self.nixosModules.printing
      self.nixosModules.graphical
      self.nixosModules.iphone-connect
      self.nixosModules.niri
      self.nixosModules.flatpak
      self.nixosModules.localsend
      self.nixosModules.tiny-share-client
      self.nixosModules.builder-cache-valley
      self.nixosModules.qmk
      self.nixosModules.sunshine
      self.nixosModules.arduino
      self.nixosModules.post-box

      # Development Assistants
      self.nixosModules.coding-agent
    ];
  };
}
