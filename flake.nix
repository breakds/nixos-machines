{
  description = "Collection of my NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nixpkgs-nvidia520.url = "github:NixOS/nixpkgs?rev=c1254eebab9a7257e978af1009d9ba2133befcec";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Use vital-modules, with the same nixpkgs
    vital-modules.url = "github:nixvital/vital-modules/dev/24.11";
    vital-modules.inputs.nixpkgs.follows = "nixpkgs";

    # Use nixos-home, with the same nixpkgs
    nixos-home.url = "github:breakds/nixos-home/dev/24.11";
    nixos-home.inputs.nixpkgs.follows = "nixpkgs";
    nixos-home.inputs.home-manager.follows = "home-manager";

    www-breakds-org.url = "github:breakds/www.breakds.org";
    www-breakds-org.inputs.nixpkgs.follows = "nixpkgs";

    wonder-devops.url = "git+ssh://git@github.com/quant-wonderland/devops-tools";
    wonder-devops.inputs.nixpkgs.follows = "nixpkgs";

    rapit.url = "git+ssh://git@github.com/breakds/rapit";
    rapit.inputs.nixpkgs.follows = "nixpkgs";

    interm.url = "git+ssh://git@github.com/breakds/interm";
    interm.inputs.nixpkgs.follows = "nixpkgs";

    ml-pkgs.url = "github:nixvital/ml-pkgs";
    ml-pkgs.inputs.nixpkgs.follows = "nixpkgs";

    game-solutions.url = "git+ssh://git@github.com/breakds/game-solutions";
    game-solutions.inputs.nixpkgs.follows = "nixpkgs";
    game-solutions.inputs.ml-pkgs.follows = "ml-pkgs";
  };

  outputs =
    { self, flake-parts, ... }@inputs: flake-parts.lib.mkFlake { inherit inputs; } {
      # Uncomment the following line to enable debug, e.g. in nix repl.
      # See https://flake.parts/debug

      # debug = true;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem = { config, pkgs, ... }: {
        # This enables running `nix fmt` over all the nix files.
        formatter = pkgs.nixfmt-classic;
        packages = {
          shuriken = pkgs.callPackage ./pkgs/shuriken {};
        };
      };

      imports = [
        ./modules/part.nix
        ./machines/malenia/part.nix
        ./machines/octavian/part.nix
        ./machines/learners/part.nix
        ./machines/ghostberry/part.nix
        ./machines/hand/part.nix
        ./machines/brock/part.nix
        ./machines/orchard/part.nix
        # ./machines/pi/part.nix
        ./machines/rei/part.nix
        ./machines/livecd/part.nix
        ./containers/part.nix
      ];

      # System agnostic attributes such as nixosModules and overlays.
      flake = {
        overlays.base = final: prev: { shriken = final.callPackage ./pkgs/shuriken { }; };
      };
    };
}
