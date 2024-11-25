# The machine "lothric" is one of the two machine learning stations.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../base/build-machines.nix
    ../common.nix
    ../../../users/xiaozhu.nix
    ../../../users/mujun.nix
  ];

  config = {
    networking = {
      hostName = "lothric";
      hostId = "db426f38";
    };

    vital.distributed-build = {
      enable = true;
      location = "homelab";
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "21.05";
  };
}
