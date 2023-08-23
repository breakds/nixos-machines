{ config, pkgs, lib, ... }:

let cfg = config.vital.oci-tooling;

    enableNvidia = builtins.elem "nvidia" config.services.xserver.videoDrivers;

in {
  options.vital.oci-tooling = {
    backend = lib.mkOption {
      type = lib.types.enum [ "docker" "podman" ];
      default = "docker";
      description = ''
        Choose between "docker" and "podman" as the tool to manage oci containers.
      '';
    };
  };

  config = {
    virtualisation.docker = {
      enable = cfg.backend == "docker";
      enableNvidia = enableNvidia;
    };

    virtualisation.podman = {
      enable = cfg.backend == "podman";
      enableNvidia = enableNvidia;
      dockerCompat = true;
    };

    virtualisation.oci-containers.backend = cfg.backend;

    environment.systemPackages = with pkgs; [
      podman-compose podman-tui
    ];
  };
}
