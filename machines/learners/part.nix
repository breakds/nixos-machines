{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations = {

    # Twin learner #2
    lorian = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit (inputs) nixpkgs-unstable; };
      modules = [
        ./lorian
        inputs.vital-modules.nixosModules.foundation
        self.nixosModules.vital-base
        inputs.nixos-home.nixosModules.breakds-home

        self.nixosModules.base-overlays
        self.nixosModules.graphical
        self.nixosModules.prometheus-exporters
        self.nixosModules.machine-learning
        self.nixosModules.ollama
        self.nixosModules.builder-cache-valley
      ];
    };

    # Heavy Learner
    radahn = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit (inputs) nixpkgs-unstable; };
      modules = [
        ./radahn
        inputs.vital-modules.nixosModules.foundation
        self.nixosModules.vital-base
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
