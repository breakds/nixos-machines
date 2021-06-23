{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
      shell = pkgs.zsh;
    };
    
    # Machine-specific networking configuration.
    networking.hostName = "rival";
    # Generated via `head -c 8 /etc/machine-id`
    networking.hostId = "efa94cac";

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;
    vital.programs.arduino.enable = true;

    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = {
      enable = true;
      remote-desktop.enable = true;
      xserver.useCapsAsCtrl = true;
    };

    environment.systemPackages = with pkgs; [
      fbreader zoom-us
    ];
  };
}
