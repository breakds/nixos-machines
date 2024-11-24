{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosConfigurations.fortress = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./fortress.nix
    ];
  };
}
