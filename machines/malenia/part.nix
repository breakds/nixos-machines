{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.malenia = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      inputs.nixos-home.nixosModules.breakds-home
      
      self.nixosModules.graphical
      self.nixosModules.iphone-connect
      # self.nixosModules.ai-agents
      self.nixosModules.steam
      self.nixosModules.machine-learning
      self.nixosModules.flatpak
      self.nixosModules.wonder-devops

      self.nixosModules.ollama
    ];
  };
}
