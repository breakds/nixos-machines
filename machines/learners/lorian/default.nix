# The machine "lorian" is one of the two machine learning stations.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../base/build-machines-v2.nix
    ./jupyter-lab.nix
    ../common.nix
    ../cassandra.nix
    ../../../users/xiaozhu.nix
    ../../../users/xin.nix
  ];

  config = {
    networking = {
      hostName = "lorian";
      hostId = "8e549b2e";
    };

    # The LLM server
    services.ollama.host = "0.0.0.0";

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.05"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "25.05";
  };
}
