{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../base
    ../../../base/i3-session-breakds.nix
    ../common/vpn.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../../data/keys/breakds_samaritan.pub
      ];
      shell = pkgs.zsh;
    };
    
    # Machine-specific networking configuration.
    networking.hostName = "zero";
    # Generated via `head -c 8 /etc/machine-id`
    networking.hostId = "26a47390";

    vital.pre-installed.level = 5;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;

    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = {
      enable = true;
      remote-desktop.enable = false;
      xserver.dpi = 120;
      xserver.useCapsAsCtrl = true;
    };

    environment.systemPackages = with pkgs; [
      zoom-us
    ];
  };
}
