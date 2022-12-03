{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../base
    ../../../base/i3-session-breakds.nix
    ../../../base/dev/breakds-dev.nix
    # TODO(breakds): Add python environment
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../../data/keys/breakds_samaritan.pub
      ];
    };

    networking = {
      hostName = "GAIL3";
      # Generated via `head -c 8 /etc/machine-id`
      hostId = "f940bd97";
    };

    vital.graphical = {
      enable = true;
      remote-desktop.enable = true;
      xserver.dpi = 108;
      nvidia.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;
    vital.programs.machine-learning.enable = true;

    environment.systemPackages = with pkgs; [
      gimp
      axel
      zoom-us
      thunderbird
    ];

    nix.settings.max-jobs = lib.mkDefault 12;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.03"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "20.03";
  };
}
