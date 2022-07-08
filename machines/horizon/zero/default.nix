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
    vital.programs = {
      vscode.enable = true;
      texlive.enable = true;
      modern-utils.enable = true;
      accounting.enable = true;
      machine-learning.enable = true;
    };

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

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?
  };
}
