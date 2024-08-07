# The machine "lothric" is one of the two machine learning stations.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../../base/build-machines.nix
    ./binary-cache.nix
    ../../../users/dustin.nix
  ];

  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    networking = {
      hostName = "radahn";
      hostId = "1d53d1f2";
    };

    services.traintrack-agent = {
      enable = false;
      port = (import ../../../data/service-registry.nix).traintrack.agents.lothric.port;
      user = "breakds";
      group = "breakds";
      settings = {
        workers = [
          # Worker 0 with 4090
          {
            gpu_id = 0;
            gpu_type = "4090";
            repos = {
              Hobot = {
                path = "/var/lib/traintrack/agent/Hobot0";
                work_dir = "/home/breakds/tmp/alf_sessions";
              };
            };
          }
          # Worker 1 with 4090
          {
            gpu_id = 1;
            gpu_type = "4090";
            repos = {
              Hobot = {
                path = "/var/lib/traintrack/agent/Hobo1";
                work_dir = "/home/breakds/tmp/alf_sessions";
              };
            };
          }
        ];
      };
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.11"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "22.11";
  };
}
