{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
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

    environment.systemPackages = with pkgs; [ chia ];

    # +----------------+
    # | Services       |
    # +----------------+

    # For mouting iSCSI disks
    services.iscsid = {
      enable = true;
      initiatorName = "iqn.2021-05.org.linux-iscsi.initiatorhost:hardstone";
      scanTargets = [{
        target = "10.77.1.119";  # hobbit2
        port = 3260;
        type = "sendtargets";
      }];
    };

    networking.firewall.allowedTCPPorts = [ 80 443 8444 ];
    # security.acme = {
    #   acceptTerms = true;
    #   email = "bds@breakds.org";
    # };

    vital.services.chiafan-workforce = {
      enable = true;
      useChiabox = false;
      farmKey = "8d3e6ed9dc07e3f38fb7321adc3481a95fbdea515f60ff9737c583c5644c6cf83a5e38e9f3e1fc01d43deef0fa1bd0be";
      poolKey = "ad0dce731a9ef1813dca8498fa37c3abda52ad76795a8327ea883e6aa6ee023f9e06e9a0d5ea1fa3c625261b9da18f12";
      workers = [
        "/var/lib/chia/plotting/nvme1:/var/lib/chia/farm/F30"
        "/var/lib/chia/plotting/nvme1:/var/lib/chia/farm/F31"
        "/var/lib/chia/plotting/nvme1:/var/lib/chia/farm/F32"
        "/var/lib/chia/plotting/nvme1:/var/lib/chia/farm/F33"
        "/var/lib/chia/plotting/nvme1:/var/lib/chia/farm/F30"
        "/var/lib/chia/plotting/nvme2:/var/lib/chia/farm/F31"
        "/var/lib/chia/plotting/nvme2:/var/lib/chia/farm/F32"
      ];
      staggering = 900;
      forwardConcurrency = 3;
    };

    services.nginx = {
      enable = false;
      package = pkgs.nginxMainline;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      # TODO(breakds): Make this per virtual host.
      clientMaxBodySize = "1000m";
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
