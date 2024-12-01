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

        services.open-webui = {
          enable = true;
          host = "0.0.0.0";
          port = 11436;
          openFirewall = false;
          environment = {
            # OLLAMA_BASE_URLS is a ";"-separated list. If you have multiple
            # here, open webui will be able to load-balance them. Note that open
            # webui has a backend, which means that the URL here is meant for
            # the backend, not the frontend (e.g. user's browser).
            OLLAMA_BASE_URLS = "http://127.0.0.1:11434";
            WEBUI_AUTH = "True";
            ANONYMIZED_TELEMETRY = "False";
            DO_NOT_TRACK = "True";
          };
        };
      };
    };
  };
}
