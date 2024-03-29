{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../users
    ../../base/dev/breakds-dev.nix
    ../../base/build-machines.nix

    # Other modules
    ./services/web-services.nix
    ./services/monitor.nix
    ./services/hydra.nix
    ./services/media.nix
    ./services/terraria.nix
    # ./services/traintrack.nix
    # TODO(breakds): Fix poetry for 23.05
    # ./services/famass.nix
    ./services/docker-registry.nix
    ./services/paperless.nix
    ../../base/tailscale.nix
  ];

  config = {
    vital.mainUser = "breakds";

    services.openssh.settings.PasswordAuthentication = false;

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

    # The LLM server
    networking.firewall.allowedTCPPorts = [ 6062 ];
    networking.firewall.allowedUDPPorts = [ 6062 ];

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

    vital.services.filerun = {
      enable = true;
      workDir = "/var/lib/filerun";
      port = 5962;
      domain = "files.breakds.org";
    };

    services.borgbackup = {
      repos.orbekk = {
        authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwihuH10KLW3zuHGz31f54PXFzspKhIdCKIWR5iBcBq" ];
        path = /var/lib/borgbackup/orbekk;
      };
    };

    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "Sun, 02:00";
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

    nixpkgs.config.permittedInsecurePackages = [
      "nix-2.17.1"
      "electron-19.1.9"      
    ];    

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
