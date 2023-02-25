{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../users
    ../../base/dev/breakds-dev.nix

    # Other modules
    ./services/web-services.nix
    ./services/monitor.nix
    ./services/hydra.nix
    ./services/media.nix
    ./services/terraria.nix
    ../../base/tailscale.nix
    ../../base/traintrack/agent.nix    
  ];

  config = {
    vital.mainUser = "breakds";

    services.openssh.passwordAuthentication = false;

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    users.users."root" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    # Allow sudo without password
    security.sudo.extraRules = [
      {
        users = [ "breakds" ];
        commands = [ { command = "ALL"; options = [ "NOPASSWD" ];} ];
      }
    ];

    networking = {
      hostName = "octavian";
      hostId = "e4f0c450";
    };

    vital.pre-installed.level = 5;

    vital.programs = {
      texlive.enable = false;
      modern-utils.enable = true;
    };

    vital.graphical = {
      enable = true;
      nvidia.enable = true;
      remote-desktop.enable = false;
    };

    # +----------------+
    # | Services       |
    # +----------------+

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "bds@breakds.org";
      };
    };

    services.nginx = {
      enable = true;
      package = pkgs.nginxMainline;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      # TODO(breakds): Make this per virtual host.
      clientMaxBodySize = "1000m";
    };

    virtualisation = {
      oci-containers.backend = "docker";
    };

    vital.services.filerun = {
      enable = true;
      workDir = "/var/lib/filerun";
      port = 5962;
      domain = "files.breakds.org";
    };

    vital.services.docker-registry = let
      info = (import ../../data/service-registry.nix).docker-registry;
    in {
      enable = true;
      domain = info.domain;
      port = info.port;
    };

    services.borgbackup = {
      repos.orbekk = {
        authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwihuH10KLW3zuHGz31f54PXFzspKhIdCKIWR5iBcBq" ];
        path = [ "/var/lib/borgbackup/orbekk" ];
      };
    };

    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "Sun, 02:00";
      };
    };

    services.traintrack-agent = {
      enable = true;
      port = (import ../../data/service-registry.nix).traintrack.agents.octavian.port;
      user = "breakds";
      group = "breakds";
      settings = {
        workers = [
          # Worker 0 with Tesla T4
          {
            gpu_id = 0;
            gpu_type = "Tesla T4";
            repos = {
              Hobot = {
                path = "/var/lib/traintrack/agent/Hobot0";
                work_dir = "/home/breakds/tmp/alf_sessions";
              };
            };
          }
        ];
      };
    };

    nix = {
      settings = {
        max-jobs = lib.mkDefault 12;
        trusted-users = [
          "root"
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
    home-manager.users."breakds".home.stateVersion = "21.05";
  };
}
