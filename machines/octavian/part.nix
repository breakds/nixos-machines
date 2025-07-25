{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosModules.first-party-software = {
    nixpkgs.overlays = [
      inputs.ml-pkgs.overlays.tools
      (final: prev: {
        www-breakds-org = inputs.www-breakds-org.defaultPackage."${final.system}";
      })
      inputs.game-solutions.overlays.kiseki
    ];
  };

  flake.nixosConfigurations.octavian = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit (inputs) nixpkgs-unstable psynker-flake; };
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      inputs.nixos-home.nixosModules.breakds-home
      inputs.beancounting.nixosModules.bcounting

      self.nixosModules.base-overlays
      self.nixosModules.graphical
      self.nixosModules.machine-learning
      self.nixosModules.first-party-software

      self.nixosModules.ollama
      inputs.personax.nixosModules.personax
      self.nixosModules.temporal
      self.nixosModules.glance
      self.nixosModules.prometheus-exporters

      inputs.psynker-flake.nixosModules.psynker-deployment
    ];
  };
}
