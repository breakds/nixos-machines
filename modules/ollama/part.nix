{ inputs, ... }:

{
  flake.nixosModules = {
    ollama = { config, lib, pkgs, ... }: {
      config = let lanExposed = config.services.ollama.host == "0.0.0.0";
      in {
        # Also install the package itself for client command line (REPL).
        environment.systemPackages = with pkgs;
          [ config.services.ollama.package ];

        # This is configured to serve from 127.0.0.1, so that only this machine
        # itself can use it.
        services.ollama = {
          enable = true;
          port = 11434;
          package = if (builtins.elem "nvidia"
            config.services.xserver.videoDrivers) then
            pkgs.ollama-cuda
          else
            pkgs.ollama;
          openFirewall = lanExposed;
        };

      };
    };
  };
}
