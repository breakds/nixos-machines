{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/dev/breakds-dev.nix
    ./jupyter-lab.nix
    # ./terraria.nix
    # ../deluge.nix
    # ../nix-serve.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    networking = {
      hostName = "gilgamesh";
      hostId = "7a4bd408";
    };

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;

    vital.programs = {
      texlive.enable = false;
      modern-utils.enable = true;
    };

    vital.graphical = {
      enable = true;
      xserver.dpi = 100;
      nvidia.enable = true;
      remote-desktop.enable = true;
    };

    # +----------------+
    # | Services       |
    # +----------------+

    services.ethminer = {
      enable = true;
      recheckInterval = 500;
      toolkit = "cuda";
      wallet = "0xcdea2bD3AC8089e9aa02cC6CF5677574f76f0df2.gilgamesh3080";
      pool = "us2.ethermine.org";
      stratumPort = 4444;
      maxPower = 340;
      registerMail = "";
      rig = "";
    };

    # vital.services.filerun = {
    #   enable = true;
    #   workDir = "/home/delegator/filerun";
    #   port = 5962;
    #   domain = "files.breakds.org";
    # };

    vital.services.gitea = {
      enable = true;
      domain = "git.breakds.org";
      port = 5965;
      appName = "Git Repos of Break and Shan";
    };

    networking.firewall.allowedTCPPorts = [
      config.vital.services.filerun.port
      config.vital.services.gitea.port
      # 6006 is for tensorboard
      6006
    ];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.09"; # Did you read the comment?
  };
}
