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

    # Eth Mining
    # services.ethminer = {
    #   enable = true;
    #   recheckInterval = 1000;
    #   toolkit = "cuda";
    #   wallet = "0xcdea2bD3AC8089e9aa02cC6CF5677574f76f0df2.samaritan3090";
    #   pool = "us2.ethermine.org";
    #   stratumPort = 4444;
    #   maxPower = 330;
    #   registerMail = "";
    #   rig = "";
    # };
  };
}
