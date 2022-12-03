# The machine "lothric" is one of the two machine learning stations.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  config = {
    networking = {
      hostName = "lothric";
      hostId = "db426f38";
    };

    services.ethminer = {
      wallet = "0xcdea2bD3AC8089e9aa02cC6CF5677574f76f0df2.lothric3090";
      maxPower = 330;
    };

    nix.settings.maxJobs = lib.mkDefault 24;

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
