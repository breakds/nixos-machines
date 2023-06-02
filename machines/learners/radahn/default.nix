# The machine "lothric" is one of the two machine learning stations.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    networking = {
      hostName = "radahn";
      hostId = "1d53d1f2";
    };

    virtualisation.docker = {
      enable = true;
      enableNvidia = true;
    };

    services.traintrack-agent = {
      enable = true;
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

    # Uncomment this if it needs gail3
    # nix = {
    #   distributedBuilds = true;
    #   buildMachines = [
    #     {
    #       hostName = "gail3";
    #       systems = [ "x86_64-linux" "i686-linux" ];
    #       maxJobs = 12;
    #       speedFactor = 3;
    #       supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
    #     }
    #     {
    #       hostName = "localhost";
    #       systems = [ "x86_64-linux" "i686-linux" ];
    #       maxJobs = lib.mkDefault 12;
    #       speedFactor = lib.mkDefault 2;
    #       supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ]; 
    #     }
    #   ];
    #   settings = {
    #     trusted-substituters = [
    #       "ssh://gail3"
    #     ];
    #   };
    # };

    nix.settings.max-jobs = lib.mkDefault 32;

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
