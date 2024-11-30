{ inputs, ... }:

{
  flake.nixosModules = {
    ollama = { config, lib, pkgs, ... }: {
      config = {
        nixpkgs.overlays = [
          (final: prev: let
            unstable = import inputs.nixpkgs-unstable {
              system = prev.system;
              config.allowUnfree = true;
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
          acceleration = if (builtins.elem "nvidia" config.services.xserver.videoDrivers)
                         then "cuda" else null;
        };

        services.nextjs-ollama-llm-ui = {
          enable = true;
          port = 11436;
        };

        networking.firewall = let
          exposeUI = config.services.nextjs-ollama-llm-ui.hostname == "0.0.0.0";
        in lib.mkIf exposeUI { allowedTCPPorts = [ config.services.nextjs-ollama-llm-ui.port ]; };
      };
    };
  };
}
