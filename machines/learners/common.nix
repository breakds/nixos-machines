{ config, pkgs, ... }:

{
  imports = [
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    vital.graphical = {
      enable = true;
      remote-desktop.enable = true;
      xserver.dpi = 100;
      nvidia.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;
    vital.programs.accounting.enable = true;
    vital.programs.vscode.enable = true;
    vital.programs.machine-learning.enable = true;

    # TODO(breakds): Re-enable ETH Mining
    services.ethminer = {
      enable = false;
      recheckInterval = 1000;
      toolkit = "cuda";
      pool = "us2.ethermine.org";
      stratumPort = 4444;
      registerMail = "";
      rig = "";
    };

    nix = {
      distributedBuilds = true;
      buildMachines = [
        {
          hostName = "richelieu";
          systems = [ "x86_64-linux" "i686-linux" ];
          maxJobs = 24;
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        }
      ];
      settings = {
        trusted-substituters = [ "ssh://richelieu" ];
      };
    };
  };
}
