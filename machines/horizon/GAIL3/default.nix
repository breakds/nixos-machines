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

    # Always use the most up-to-date linux kernel since this machine
    # has a super new CPU i9-11900KF.
    #
    # We can probably remove this when 5.12 becomes the stable kernel.
    boot.kernelPackages = pkgs.linuxPackages_latest;

    vital.graphical = {
      enable = true;
      remote-desktop.enable = true;
      xserver.dpi = 120;
      nvidia.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;

    # For ROS
    networking.firewall.allowedTCPPorts = [ 11311 ];

    environment.systemPackages = with pkgs; [
      gimp
      axel
      zoom-us
      thunderbird
    ];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.03"; # Did you read the comment?
  };
}
