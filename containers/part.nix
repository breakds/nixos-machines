{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.fortress = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./fortress.nix
      self.nixosModules.security-patches
    ];
  };

  flake.nixosModules = {
    post-box = import ./post-box.nix;
  };
}
