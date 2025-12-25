{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.forgery = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      self.nixosModules.vital-base
      inputs.nixos-home.nixosModules.breakds-home

      self.nixosModules.graphical

      ({
        nixpkgs.overlays = [ inputs.ml-pkgs.overlays.tools ];
      })

      inputs.beancounting.nixosModules.bcounting
    ];
  };
}
