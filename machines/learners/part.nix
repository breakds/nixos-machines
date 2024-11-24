{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations = {

    # Twin learner #1
    lothric = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./lothric
        inputs.vital-modules.nixosModules.foundation
        inputs.nixos-home.nixosModules.breakds-home
      
        self.nixosModules.graphical
        self.nixosModules.machine-learning
      ];
    };

    # Twin learner #2
    lorian = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./lorian
        inputs.vital-modules.nixosModules.foundation
        inputs.nixos-home.nixosModules.breakds-home
      
        self.nixosModules.graphical
        self.nixosModules.machine-learning
      ];
    };

    # Heavy Learner
    radahn = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./radahn
        inputs.vital-modules.nixosModules.foundation
        inputs.nixos-home.nixosModules.breakds-home
      
        self.nixosModules.graphical
        self.nixosModules.machine-learning
      ];
    };
  };
}
