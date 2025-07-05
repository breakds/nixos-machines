{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations = {

    # Twin learner #2
    lorian = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./lorian
        inputs.vital-modules.nixosModules.foundation
        inputs.nixos-home.nixosModules.breakds-home

        self.nixosModules.base-overlays
        self.nixosModules.graphical
        self.nixosModules.prometheus-exporters
        self.nixosModules.machine-learning
        self.nixosModules.ollama
      ];
    };

    # Heavy Learner
    radahn = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./radahn
        inputs.vital-modules.nixosModules.foundation
        inputs.nixos-home.nixosModules.breakds-home

        self.nixosModules.base-overlays
        self.nixosModules.graphical
        self.nixosModules.prometheus-exporters        
        self.nixosModules.machine-learning
        self.nixosModules.ollama
      ];
    };
  };
}
