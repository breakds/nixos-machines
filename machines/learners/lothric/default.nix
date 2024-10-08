# The machine "lothric" is one of the two machine learning stations.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../base/build-machines.nix
    ../common.nix
    ../../../users/xiaozhu.nix    
  ];

  config = {
    networking = {
      hostName = "lothric";
      hostId = "db426f38";
    };

    services.traintrack-agent = {
      enable = false;
      port = (import ../../../data/service-registry.nix).traintrack.agents.lothric.port;
      user = "breakds";
      group = "breakds";
      settings = {
        workers = [
          # Worker 0 with 3090
          {
            gpu_id = 0;
            gpu_type = "3090";
            repos = {
              Hobot = {
                path = "/var/lib/traintrack/agent/Hobot0";
                work_dir = "/home/breakds/tmp/alf_sessions";
              };
            };
          }
          # Worker 1 with 3090
          {
            gpu_id = 1;
            gpu_type = "3090";
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

    vital.distributed-build = {
      enable = true;
      location = "homelab";
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "21.05";
  };
}
