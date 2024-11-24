{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.hand = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      inputs.nixos-home.nixosModules.breakds-home
      inputs.nixos-hardware.nixosModules.framework-12th-gen-intel

      self.nixosModules.laptop
      self.nixosModules.graphical
      self.nixosModules.iphone-connect
      self.nixosModules.ai-agents
      self.nixosModules.steam
      self.nixosModules.flatpak
    ];
  };
}
