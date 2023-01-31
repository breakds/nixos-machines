{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/dev/breakds-dev.nix

    # Other modules
    ./services/web-services.nix
    # ./monitor.nix
  ];

  config = {
    vital.mainUser = "breakds";

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
      nvidia.enable = false;
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

    # vital.services.filerun = {
    #   enable = true;
    #   workDir = "/var/lib/filerun";
    #   port = 5962;
    #   domain = "files.breakds.org";
    # };

    nix = {
      settings = {
        max-jobs = lib.mkDefault 28;
        trusted-users = [
          "root"
        ];
      };
    };

    # services.borgbackup = {
    #   repos.orbekk = {
    #     authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwihuH10KLW3zuHGz31f54PXFzspKhIdCKIWR5iBcBq" ];
    #     path = [ "/var/lib/borgbackup/orbekk" ];
    #   };
    #   # backups.richelieu2dragon = let keyPath = "/home/breakds/.ssh/breakds_samaritan"; in {
    #   #   paths = [ "/var/lib/filerun/user-files/Archive" ];
    #   #   exclude = [];
    #   #   doInit = true;
    #   #   repo = "borg@dragon.orbekk.com:.";
    #   #   encryption = {
    #   #     mode = "repokey-blake2";
    #   #     passCommand = "cat ${keyPath}";
    #   #   };
    #   #   environment = { BORG_RSH = "ssh -i ${keyPath}"; };
    #   #   compression = "auto,lzma";
    #   #   startAt = "daily";
    #   # };
    # };

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