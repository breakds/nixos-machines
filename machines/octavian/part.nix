{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosModules.first-party-software = {
    nixpkgs.overlays = [
      (final: prev: {
        www-breakds-org = inputs.www-breakds-org.defaultPackage."${final.system}";
      })
      inputs.game-solutions.overlays.kiseki
    ];
  };

  flake.nixosConfigurations.octavian = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit (inputs) nixpkgs-unstable stt-server; };
    modules = [
      ./.
      self.nixosModules.vital-base
      inputs.nixos-home.nixosModules.breakds-home
      # inputs.beancounting.nixosModules.bcounting

      self.nixosModules.base-overlays
      self.nixosModules.graphical
      self.nixosModules.machine-learning
      self.nixosModules.first-party-software

      self.nixosModules.ollama
      self.nixosModules.glance
      self.nixosModules.prometheus-exporters
      self.nixosModules.filerun

      inputs.www-psynk-ai.nixosModules.www-psynk-ai
      ({config, ... }: {
        services.www-psynk-ai.environmentFile = "/home/breakds/.config/www-psynk-ai/env";
      })

      inputs.stt-server.nixosModules.default
    ];
  };
}
