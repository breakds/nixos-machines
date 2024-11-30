{ inputs, ... }:

{
  flake.nixosModules = {
    ollama = { config, lib, pkgs, ... }: {
      config = let
        lanExposed = config.services.ollama.host == "0.0.0.0";
      in {
        nixpkgs.overlays = [
          (final: prev: let
            unstable = import inputs.nixpkgs-unstable {
              system = prev.system;
              config.allowUnfree = true;
            }; in {
              inherit (unstable) ollama ollama-cuda;
            })
        ];

        # Also install the package itself for client command line (REPL).
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
          openFirewall = lanExposed;
        };

        services.nextjs-ollama-llm-ui = {
          enable = true;
          port = 11436;
          hostname = config.services.ollama.host;
        };

        networking.firewall = lib.mkIf lanExposed { allowedTCPPorts = [ config.services.nextjs-ollama-llm-ui.port ]; };
      };
    };
  };
}
