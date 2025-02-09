{ inputs, ... }:

{
  flake.nixosModules = {
    goose-ai = { config, lib, pkgs, ... }: {
      config = {
        nixpkgs.overlays = [
          inputs.ml-pkgs.overlays.gen-ai
        ];

        # Also install the package itself for client command line (REPL).
        environment.systemPackages = with pkgs; [
          goose-cli
        ];
      };
    };
  };
}
