{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../base
    ./chia-helper.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../data/keys/breakds_samaritan.pub
      ];
      shell = pkgs.bash;
    };

    networking = {
      hostName = "hardstone";
      hostId = "c62019c7";
    };

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;

    vital.graphical = {
      enable = true;
      xserver.dpi = 100;
      nvidia.enable = true;
      remote-desktop.enable = true;
    };

    # +----------------+
    # | Services       |
    # +----------------+

    networking.firewall.allowedTCPPorts = [ 80 443 ];
    # security.acme = {
    #   acceptTerms = true;
    #   email = "bds@breakds.org";
    # };

    services.nginx = {
      enable = false;
      package = pkgs.nginxMainline;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      # TODO(breakds): Make this per virtual host.
      clientMaxBodySize = "1000m";
    };

    vital.services.chia-blockchain = {
      enable = false;
      plottingDirectory = "/opt/chia/plotting";
      plotsDirectory = "/home/breakds/plots";
      dotchiaDirectory = "/opt/chia/dotchia";
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.09"; # Did you read the comment?
  };
}
