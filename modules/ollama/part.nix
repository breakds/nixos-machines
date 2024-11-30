{ inputs, ... }:

{
  flake.nixosModules = {
    ollama = { config, lib, pkgs, ... }: {
      nixpkgs.overlays = [
        (final: prev: let
          unstable = import inputs.nixpkgs-unstable {
            system = prev.system;
          }; in {
            inherit (unstable) ollama ollama-cuda;
          })
      ];

      environment.systemPackages = with pkgs; [
        ollama
      ];

      # This is configured to serve from 127.0.0.1, so that only this machine
      # itself can use it.
      services.ollama = {
        enable = true;
        port = 11434;
      };

      services.nextjs-ollama-llm-ui = {
        enable = true;
        port = 11436;
      };
    };
  };
}
