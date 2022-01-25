{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/dev/breakds-dev.nix
    ./homepage.nix
    ./jupyter-lab.nix
    ./jiahaotian.nix
    ./linxiao.nix    
    ./terraria.nix
    # ../deluge.nix
    # ../nix-serve.nix
  ];

  config = {
    vital.mainUser = "breakds";

    boot.kernelPackages = pkgs.linuxPackages_latest;

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    # Allow sudo without password
    security.sudo.extraRules = [
      {
        users = [ "breakds" ];
        commands = [ { command = "ALL"; options = [ "NOPASSWD" ];} ];
      }
    ];

    networking = {
      hostName = "richelieu";
      hostId = "baae7a72";

      useDHCP = false;
      interfaces = {
        eno1.useDHCP = true;
        eno2.useDHCP = true;
        eno3.useDHCP = true;
        eno4.useDHCP = true;
      };
    };

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;

    vital.programs = {
      texlive.enable = false;
      modern-utils.enable = true;
    };

    vital.graphical = {
      enable = true;
      xserver.dpi = 100;
      nvidia.enable = false;
      remote-desktop.enable = false;
    };

    # +----------------+
    # | Services       |
    # +----------------+

    # 6006 is for tensorboard
    networking.firewall.allowedTCPPorts = [ 80 443 6006 ];
    
    security.acme = {
      acceptTerms = true;
      email = "bds@breakds.org";
    };

    services.nginx = {
      enable = true;
      package = pkgs.nginxMainline;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      # TODO(breakds): Make this per virtual host.
      clientMaxBodySize = "1000m";
    };

    vital.services.docker-registry = {
      enable = true;
      domain = "docker.breakds.org";
      port = 5050;
    };

    vital.services.filerun = {
      enable = true;
      workDir = "/var/lib/filerun";
      port = 5962;
      domain = "files.breakds.org";
    };

    services.borgbackup.repos = {
      orbekk = {
        authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwihuH10KLW3zuHGz31f54PXFzspKhIdCKIWR5iBcBq" ];
        path = [ "/var/lib/borgbackup/orbekk" ];
      };      
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?
  };
}
