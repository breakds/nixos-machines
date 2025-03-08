{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosModules.first-party-software = {
    nixpkgs.overlays = [
      (final: prev: {
        www-breakds-org = inputs.www-breakds-org.defaultPackage."${final.system}";
      })
      inputs.game-solutions.overlays.kiseki
      inputs.rsu-taxer.overlays.default
      # inputs.rapit.overlays.default
    ];
  };

  flake.nixosConfigurations.octavian = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      inputs.nixos-home.nixosModules.breakds-home

      self.nixosModules.graphical
      self.nixosModules.machine-learning
      self.nixosModules.first-party-software

      self.nixosModules.ollama
      inputs.personax.nixosModules.personax
    ];
  };
}
